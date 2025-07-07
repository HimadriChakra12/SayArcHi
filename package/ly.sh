#!/bin/bash

# Exit on error
set -e

# Install ly display manager
sudo pacman -S --noconfirm ly

# Enable ly service
sudo systemctl enable ly.service

# Optionally, start ly immediately (uncomment if desired)
# sudo systemctl start ly.service

echo "Ly installed and enabled."

