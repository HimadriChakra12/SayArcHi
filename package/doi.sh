#!/bin/bash
sudo pacman -S base-devel git mupdf

path="$HOME/pkg"
doi="$path/doi"

mkdir -p $path

if [ -d $doi ]; then
    cd $doi
    git pull
else
    git clone https://github.com/HimadriChakra12/doi.git $doi
fi

cd $doi
git checkout My-Build
bash install.sh
