#!/bin/sh
# SPDX-License-Identifier: EUPL-1.2
# Copyright © 2025 AW6

cd ~/
python3 -m venv ~/comfy
git clone https://github.com/comfyanonymous/ComfyUI.git

# Install GPU appropriate packages
if [[ $(lshw -C display 2>/dev/null | grep -i vendor) =~ [Nn][Vv][Ii][Dd][Ii][Aa] ]]; then
    echo "NVIDIA GPU detected, downloading CUDA version..."
    ~/comfy/bin/pip install pip install torch torchvision torchaudio --extra-index-url https://download.pytorch.org/whl/cu130
else
    echo "No NVIDIA GPU detected, downloading non-CUDA version..."
    ~/comfy/bin/pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/rocm6.4
fi

wget -nv -P ComfyUI/models/vae https://huggingface.co/Comfy-Org/Qwen-Image_ComfyUI/resolve/main/split_files/vae/qwen_image_vae.safetensors &
wget -nv -P ComfyUI/models/text_encoders https://huggingface.co/Comfy-Org/Qwen-Image_ComfyUI/resolve/main/split_files/text_encoders/qwen_2.5_vl_7b_fp8_scaled.safetensors &
wget -nv -P ComfyUI/models/loras https://huggingface.co/lightx2v/Qwen-Image-Lightning/resolve/main/Qwen-Image-Lightning-8steps-V1.0.safetensors &
wget -nv -P ComfyUI/models/diffusion_models https://huggingface.co/Comfy-Org/Qwen-Image_ComfyUI/resolve/main/split_files/diffusion_models/qwen_image_fp8_e4m3fn.safetensors &
wget -nv -P ComfyUI/models/diffusion_models https://huggingface.co/Comfy-Org/Qwen-Image-Edit_ComfyUI/resolve/main/split_files/diffusion_models/qwen_image_edit_2509_fp8_e4m3fn.safetensors &
wget -nv -P ComfyUI/models/loras https://huggingface.co/lightx2v/Qwen-Image-Lightning/resolve/main/Qwen-Image-Edit-2509/Qwen-Image-Edit-2509-Lightning-4steps-V1.0-bf16.safetensors &
wget -nv -P ComfyUI/models/loras https://huggingface.co/lightx2v/Qwen-Image-Lightning/resolve/main/Qwen-Image-Lightning-4steps-V1.0.safetensors &


cd ~/ComfyUI/custom_nodes
git clone https://github.com/Comfy-Org/ComfyUI-Manager.git &
git clone https://github.com/1038lab/ComfyUI-QwenVL.git
git clone https://github.com/1038lab/ComfyUI-RMBG
git clone https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite.git
git clone https://github.com/rgthree/rgthree-comfy.git &
git clone https://github.com/JPS-GER/ComfyUI_JPS-Nodes.git &
git clone https://github.com/ltdrdata/ComfyUI-Impact-Pack comfyui-impact-pack


~/comfy/bin/pip install -r ~/ComfyUI/requirements.txt -r ComfyUI-QwenVL/requirements.txt -r ComfyUI-RMBG/requirements.txt -r ComfyUI-VideoHelperSuite/requirements.txt -r comfyui-impact-pack/requirements.txt &


wait
cd ~/ComfyUI
~/comfy/bin/python3 main.py --listen --enable-cors-header "*" &
