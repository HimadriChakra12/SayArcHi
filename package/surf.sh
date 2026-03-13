#!/bin/bash
sudo pacman -S base-devel git mupdf

path="$HOME/pkg"
dwarf="$path/dwarf"

mkdir -p $path

if [ -d $dwarf ]; then
    cd $dwarf
    git pull
else
    git clone https://github.com/HimadriChakra12/dwarf.git $dwarf
fi

cd $dwarf
bash install.sh

