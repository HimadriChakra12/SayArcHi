#!/bin/bash

set -e

echo "==> Installing reflector..."
sudo pacman -S --needed --noconfirm reflector

echo "==> Backing up current mirrorlist..."
sudo cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup

echo "==> Generating optimized mirrorlist..."
sudo reflector \
  --country Singapore,India,Japan,South\ Korea,Hong\ Kong \
  --protocol https \
  --latest 20 \
  --sort rate \
  --threads 20 \
  --save /etc/pacman.d/mirrorlist

echo "==> Enabling reflector systemd timer..."
sudo systemctl enable reflector.timer
sudo systemctl start reflector.timer

sudo pacman -Syyu
echo "==> Done!"
echo "Mirrorlist updated and automatic updates enabled."

