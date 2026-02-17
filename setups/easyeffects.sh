#!/bin/bash

set -e

echo "Installing core PipeWire stack..."
sudo pacman -S --needed \
    pipewire \
    pipewire-alsa \
    pipewire-pulse \
    pipewire-jack \
    wireplumber \
    gst-plugin-pipewire \
    lsp-plugins \
    calf \
    zam-plugins \
    rnnoise

echo "Installing EasyEffects (AUR)..."

if ! command -v yay &> /dev/null; then
    echo "Installing yay AUR helper..."
    sudo pacman -S --needed base-devel git
    git clone https://aur.archlinux.org/yay.git
    cd yay
    makepkg -si
    cd ..
fi

yay -S --needed easyeffects

echo "Enabling PipeWire services..."
systemctl --user enable pipewire pipewire-pulse wireplumber
systemctl --user restart pipewire pipewire-pulse wireplumber

echo "EasyEffects setup complete."

