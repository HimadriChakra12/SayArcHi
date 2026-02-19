#!/bin/bash
sudo pacman -S base-devel git imlib2 libx11 libxft libxinerama libxrandr

path="$HOME/git"
mkdir -p $path
git clone https://github.com/HimadriChakra12/sxiv.git $path/sxiv

cd $path/sxiv
bash install.sh
