#!/bin/bash
set -e

sudo pacman -S --noconfirm ly

sudo systemctl enable ly.service 2>/dev/null || \
sudo systemctl enable ly@tty1.service 2>/dev/null || \
sudo systemctl enable ly@tty2.service

echo "Ly installed and enabled."

sudo cp $HOME/.dotfiles/ly/config.ini /etc/ly/ -f
