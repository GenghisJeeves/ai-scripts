#!/bin/bash
# SPDX-License-Identifier: EUPL-1.2
# Copyright © 2025 AW6
#
# Script to download GGUF models from Hugging Face
# Usage: ./download_gguf.sh [repo_id] [filename_pattern] [destination_dir]
#
# Examples:
# Make script executable
# chmod +x download_gguf.sh
#
# Download all GGUF files from a repository
# ./download_gguf.sh TheBloke/Llama-2-7B-Chat-GGUF
#
# Download only Q4 quantized files
# ./download_gguf.sh TheBloke/Llama-2-7B-Chat-GGUF "*q4_0*.gguf"
#
# Download to specific directory
# ./download_gguf.sh TheBloke/Llama-2-7B-Chat-GGUF "*.gguf" /path/to/models

set -e  # Exit on any error

# Default values
REPO_ID="${1:-TheBloke/Llama-2-7B-Chat-GGUF}"
FILENAME_PATTERN="${2:-*.gguf}"
DEST_DIR="${3:-./models}"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to get file list from Hugging Face API
get_file_list() {
    local repo_id="$1"
    local api_url="https://huggingface.co/api/models/${repo_id}"

    print_info "Fetching file list from ${repo_id}..."

    # Use curl to get the model info and extract GGUF files matching the pattern
    file_list=$(curl -s "$api_url" | \
                grep -o '"rfilename":"[^"]*' | \
                cut -d'"' -f4 | \
                grep -E "$(echo "$FILENAME_PATTERN" | sed 's/\./\\./g; s/\*/.*/g')" | \
                sort)

    if [ -z "$file_list" ]; then
        print_error "No files matching pattern '$FILENAME_PATTERN' found in repository $REPO_ID"
        return 1
    fi

    echo -e "The following files are found: \n$file_list"
}

# Function to download a single file
download_file() {
    local repo_id="$1"
    local filename="$2"
    local dest_dir="$3"

    local url="https://huggingface.co/${repo_id}/resolve/main/${filename}"
    local dest_path="${dest_dir}/${filename}"

    # Create destination directory if it doesn't exist
    mkdir -p "$dest_dir"

    print_info "Downloading: $filename from $url"

    # Download with progress bar
    if wget --progress=bar:force -O "$dest_path" "$url"; then
        print_info "Successfully downloaded: $filename"
        echo "$dest_path"
        return 0
    else
        print_error "Failed to download: $filename"
        rm -f "$dest_path"  # Clean up partial download
        return 1
    fi
}

# Main execution
main() {
    print_info "Starting download process..."
    print_info "Repository: $REPO_ID"
    print_info "File pattern: $FILENAME_PATTERN"
    print_info "Destination: $DEST_DIR"

    # Get list of files to download
    files=$(get_file_list "$REPO_ID")
    if [ $? -ne 0 ]; then
        print_error "Failed to retrieve file list from repository. Exiting."
        exit 1
    fi

    # Convert to array and filter out empty lines
    readarray -t file_array <<< "$files"
    filtered_files=()
    for file in "${file_array[@]}"; do
        if [ -n "$file" ] && [ "$file" != "" ]; then
            filtered_files+=("$file")
        fi
    done
    
    # Count files and display
    file_count=${#filtered_files[@]}
    if [ $file_count -eq 0 ]; then
        print_error "No valid files found to download"
        print_error "Script cannot continue without files to download. Exiting."
        exit 1
    fi
    
    print_info "Found $file_count file(s) matching the pattern"

    for file in "${filtered_files[@]}"; do
        print_info "  - $file from URL: https://huggingface.co/${REPO_ID}/resolve/main/${file}"
    done

    # Download files simultaneously
    downloaded_files=()
    first_file=""
    pids=()
    temp_dir=$(mktemp -d)

    print_info "Starting simultaneous downloads..."

    # Start all downloads in background
    for i in "${!filtered_files[@]}"; do
        file="${filtered_files[$i]}"
        (
            set +e  # Don't exit on error in subshell
            result=$(download_file "$REPO_ID" "$file" "$DEST_DIR")
            exit_code=$?
            echo "$exit_code:$result" > "$temp_dir/result_$i"
        ) &
        pids+=($!)
    done

    # Wait for all downloads to complete
    print_info "Waiting for downloads to complete..."
    for pid in "${pids[@]}"; do
        wait $pid
    done

    # Collect results
    for i in "${!filtered_files[@]}"; do
        if [ -f "$temp_dir/result_$i" ]; then
            result_line=$(cat "$temp_dir/result_$i")
            exit_code="${result_line%%:*}"
            result_path="${result_line#*:}"
            
            if [ "$exit_code" -eq 0 ] && [ -n "$result_path" ] && [ -f "$result_path" ]; then
                downloaded_files+=("$result_path")
                # Set first_file only once
                if [ -z "$first_file" ]; then
                    first_file="$result_path"
                fi
            fi
        fi
    done

    # Clean up temporary directory
    rm -rf "$temp_dir"

    # Set environment variables
    if [ -n "$first_file" ]; then
        # Export variables for current shell and subprocesses
        export GGUF_MODEL_PATH="$first_file"
        export GGUF_MODEL_DIR="$DEST_DIR"
        export GGUF_FIRST_FILE="$(basename "$first_file")"

        # If multiple files, set additional variable
        if [ ${#downloaded_files[@]} -gt 1 ]; then
            export GGUF_MULTIPLE_FILES="true"
            print_warning "Multiple files downloaded. GGUF_MODEL_PATH set to first file: $(basename "$first_file")"
        else
            export GGUF_MULTIPLE_FILES="false"
        fi

        print_info "Environment variables set:"
        print_info "  GGUF_MODEL_PATH=$GGUF_MODEL_PATH"
        print_info "  GGUF_MODEL_DIR=$GGUF_MODEL_DIR"
        print_info "  GGUF_FIRST_FILE=$GGUF_FIRST_FILE"
        print_info "  GGUF_MULTIPLE_FILES=$GGUF_MULTIPLE_FILES"

        # Create a script to source for other shells
        cat > "${DEST_DIR}/gguf_vars.sh" << EOF
#!/bin/bash
export GGUF_MODEL_PATH="$GGUF_MODEL_PATH"
export GGUF_MODEL_DIR="$GGUF_MODEL_DIR"
export GGUF_FIRST_FILE="$GGUF_FIRST_FILE"
export GGUF_MULTIPLE_FILES="$GGUF_MULTIPLE_FILES"
EOF

        print_info "Variables also saved to: ${DEST_DIR}/gguf_vars.sh"
        print_info "To use in another shell, run: source ${DEST_DIR}/gguf_vars.sh"

    else
        print_error "No files were successfully downloaded"
        print_error "All download attempts failed. Check network connection and repository access. Exiting."
        exit 1
    fi

    print_info "Download process completed!"
}

# Run main function
main "$@"
