#!/bin/bash
# SPDX-License-Identifier: EUPL-1.2
# Copyright © 2025 AW6

# Runpod Stuff
apt update
mkdir -p /workspace
DEBIAN_FRONTEND=noninteractive apt-get install openssh-server -y
mkdir -p ~/.ssh
chmod 700 ~/.ssh
echo "$PUBLIC_KEY" >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/*
service ssh start


# Basic AW6 install, probably don't need X11
apt upgrade -y
apt install -y wget pip python3-venv xorg nvtop htop fish byobu nano git rsync lshw lsof

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

# Get other scrips
cd ~/
git clone https://github.com/GenghisJeeves/ai-scripts.git
chmod +x ai-scripts/*

~/ai-scripts/comfyui.sh &
~/ai-scripts/kobold.sh &
