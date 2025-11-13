#!/bin/sh
# SPDX-License-Identifier: EUPL-1.2
# Copyright © 2025 AW6
apt update
apt install -y wget
mkdir -p /workspace
DEBIAN_FRONTEND=noninteractive apt-get install openssh-server -y
mkdir -p ~/.ssh
chmod 700 ~/.ssh
echo "$PUBLIC_KEY" >> ~/.ssh/authorized_keys
echo "$SSHKey" >> ~/.ssh/id_ed25519
chmod 600 ~/.ssh/*
service ssh start
apt upgrade -y
apt install -y pip python3-venv xorg nvtop htop fish byobu nano git rsync lshw lsof

echo "function fish_right_prompt" > /etc/fish/conf.d/prompt.fish
echo "  set -l seconds (math \"\$CMD_DURATION / 1000\")" >> /etc/fish/conf.d/prompt.fish
echo "  if test \"\$CMD_DURATION\" -gt 0" >> /etc/fish/conf.d/prompt.fish
echo "echo (set_color blue)\"[\$seconds s]\"(set_color normal)" >> /etc/fish/conf.d/prompt.fish
echo "  end" >> /etc/fish/conf.d/prompt.fish
echo "end" >> /etc/fish/conf.d/prompt.fish
chmod 0644 /etc/fish/conf.d/prompt.fish
echo "/usr/bin/fish" > /etc/byobu/shell
chmod 0644 /etc/byobu/shell
echo "set -g default-shell /usr/bin/fish" > /etc/byobu/keybindings.tmux
echo "set -g default-command /usr/bin/fish" >> /etc/byobu/keybindings.tmux
chmod 0644 /etc/byobu/keybindings.tmux
echo "if [ -t 1 ]; then" > /etc/profile.d/fish-default.sh
echo "  if [ -z "$BYOBU_WINDOW" ] && [ -z "$TMUX" ]; then" >> /etc/profile.d/fish-default.sh
echo "export SHELL=/usr/bin/fish" >> /etc/profile.d/fish-default.sh
echo "  fi" >> /etc/profile.d/fish-default.sh
echo "fi" >> /etc/profile.d/fish-default.sh
byobu-enable

# Install Ollama
#curl -fsSL https://ollama.com/install.sh | sh &

cd /root/
python3 -m venv /root/venv
git clone https://github.com/comfyanonymous/ComfyUI.git

# Install GPU appropriate packages
if [[ $(lshw -C display 2>/dev/null | grep -i vendor) =~ [Nn][Vv][Ii][Dd][Ii][Aa] ]]; then
    echo "NVIDIA GPU detected, downloading CUDA version..."
    wget -nv https://github.com/LostRuins/koboldcpp/releases/latest/download/koboldcpp-linux-x64 && mv koboldcpp-linux-x64 koboldcpp
    venv/bin/pip install pip install torch torchvision torchaudio --extra-index-url https://download.pytorch.org/whl/cu130
else
    echo "No NVIDIA GPU detected, downloading non-CUDA version..."
    wget -nv https://koboldai.org/cpplinuxrocm && mv cpplinuxrocm koboldcpp
    /root/venv/bin/pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/rocm6.4
fi

/root/venv/bin/pip install -r ComfyUI/requirements.txt &
wget -nv -P ComfyUI/models/vae https://huggingface.co/Comfy-Org/Qwen-Image_ComfyUI/resolve/main/split_files/vae/qwen_image_vae.safetensors &
wget -nv -P ComfyUI/models/text_encoders https://huggingface.co/Comfy-Org/Qwen-Image_ComfyUI/resolve/main/split_files/text_encoders/qwen_2.5_vl_7b_fp8_scaled.safetensors &
wget -nv -P ComfyUI/models/loras https://huggingface.co/lightx2v/Qwen-Image-Lightning/resolve/main/Qwen-Image-Lightning-8steps-V1.0.safetensors &
wget -nv -P ComfyUI/models/diffusion_models https://huggingface.co/Comfy-Org/Qwen-Image_ComfyUI/resolve/main/split_files/diffusion_models/qwen_image_fp8_e4m3fn.safetensors &
wget -nv -P ComfyUI/models/diffusion_models https://huggingface.co/Comfy-Org/Qwen-Image-Edit_ComfyUI/resolve/main/split_files/diffusion_models/qwen_image_edit_2509_fp8_e4m3fn.safetensors &
wget -nv -P ComfyUI/models/loras https://huggingface.co/lightx2v/Qwen-Image-Lightning/resolve/main/Qwen-Image-Edit-2509/Qwen-Image-Edit-2509-Lightning-4steps-V1.0-bf16.safetensors &
wget -nv -P ComfyUI/models/loras https://huggingface.co/lightx2v/Qwen-Image-Lightning/resolve/main/Qwen-Image-Lightning-4steps-V1.0.safetensors &


# Get Kobold CPP Model
python3 -m venv /root/hf
/root/hf/bin/pip install "huggingface_hub[cli]"
/root/hf/bin/huggingface-cli download bartowski/Qwen2-72B-Instruct-GGUF --include "Qwen2-72B-Instruct-Q8_0.gguf/*" --local-dir Qwen2-72B-Instruct-Q8_0



#wget -nv https://huggingface.co/bartowski/TheDrummer_Behemoth-X-123B-v2-GGUF/resolve/main/TheDrummer_Behemoth-X-123B-v2-Q6_K/TheDrummer_Behemoth-X-123B-v2-Q6_K-00001-of-00003.gguf &
#wget -nv https://huggingface.co/bartowski/TheDrummer_Behemoth-X-123B-v2-GGUF/resolve/main/TheDrummer_Behemoth-X-123B-v2-Q6_K/TheDrummer_Behemoth-X-123B-v2-Q6_K-00002-of-00003.gguf &
#wget -nv https://huggingface.co/bartowski/TheDrummer_Behemoth-X-123B-v2-GGUF/resolve/main/TheDrummer_Behemoth-X-123B-v2-Q6_K/TheDrummer_Behemoth-X-123B-v2-Q6_K-00003-of-00003.gguf &

cd /root/ComfyUI/custom_nodes
git clone https://github.com/Comfy-Org/ComfyUI-Manager.git &
git clone https://github.com/1038lab/ComfyUI-QwenVL.git
git clone https://github.com/1038lab/ComfyUI-RMBG
git clone https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite.git
git clone https://github.com/rgthree/rgthree-comfy.git &
git clone https://github.com/JPS-GER/ComfyUI_JPS-Nodes.git &
git clone https://github.com/ltdrdata/ComfyUI-Impact-Pack comfyui-impact-pack

/root/venv/bin/pip install -r ComfyUI-QwenVL/requirements.txt -r ComfyUI-RMBG/requirements.txt -r ComfyUI-VideoHelperSuite/requirements.txt -r comfyui-impact-pack/requirements.txt &


wait
cd /root/ComfyUI
/root/venv/bin/python3 main.py --listen --enable-cors-header "*" &
ssh -o "StrictHostKeyChecking no" $ReverseSSHUser "rm /home/aw6/www/ai-rp-01.aw6.co.uk/proxy.sock"
#watch "rsync -r  ~/ComfyUI/output/ $ReverseSSHUser:/home/aw6/www/s.aw6.uk/ai-03" &
#ssh $ReverseSSHUser -R /home/aw6/www/ai-rp-01.aw6.co.uk/proxy.sock:localhost:8188
cd /root/
chmod +x koboldcpp
./koboldcpp --contextsize 131072 --gpulayers 999 --flashattention --model TheDrummer_Behemoth-X-123B-v2-Q6_K-00001-of-00003.gguf &
