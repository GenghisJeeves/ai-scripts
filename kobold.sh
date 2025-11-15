#!/bin/sh
# SPDX-License-Identifier: EUPL-1.2
# Copyright © 2025 AW6

cd ~/
python3 -m venv ~/kobold
# Install GPU appropriate packages
if [[ $(lshw -C display 2>/dev/null | grep -i vendor | grep -oi 'Nvidia') =~ [Nn][Vv][Ii][Dd][Ii][Aa] ]]; then
    echo "NVIDIA GPU detected, downloading CUDA version..."
    wget -nv https://github.com/LostRuins/koboldcpp/releases/latest/download/koboldcpp-linux-x64 && mv koboldcpp-linux-x64 koboldcpp &
    ~/kobold/bin/pip install torch torchvision torchaudio --extra-index-url https://download.pytorch.org/whl/cu130 &
else
    echo "No NVIDIA GPU detected, downloading non-CUDA version..."
    wget -nv https://koboldai.org/cpplinuxrocm && mv cpplinuxrocm koboldcpp &
    ~/kobold/bin/pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/rocm6.4 &
fi


~/ai-scripts/download_gguf.sh $GGUF_REPOSITORY "*$GGUF_QUANT*.gguf" ~/
wait
chmod +x ~/koboldcpp
~/koboldcpp --model $GGUF_MODEL_DIR/$GGUF_MODEL_PATH --contextsize $GGUF_CONTEXT --gpulayers $GGUF_GPU_LAYERS &

