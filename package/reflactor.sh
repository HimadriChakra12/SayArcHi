#!/bin/bash

set -e

echo "==> Installing reflector..."
sudo pacman -S --needed --noconfirm reflector

echo "==> Backing up current mirrorlist..."
sudo cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup

echo "==> Generating optimized mirrorlist..."
sudo reflector \
  --country US \
  --latest 20 \
  --protocol https \
  --sort rate \
  --save /etc/pacman.d/mirrorlist

echo "==> Enabling reflector systemd timer..."
sudo systemctl enable reflector.timer
sudo systemctl start reflector.timer

echo "==> Done!"
echo "Mirrorlist updated and automatic updates enabled."

