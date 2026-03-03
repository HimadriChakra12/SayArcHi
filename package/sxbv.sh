#!/bin/bash
sudo pacman -S base-devel git mupdf

path="$HOME/pkg"
sxbv="$path/sxbv"

mkdir -p $path

if [ -d $sxbv ]; then
    cd $sxbv
    git pull
else
    git clone https://github.com/HimadriChakra12/sxbv.git $sxbv
fi

cd $sxbv
bash install.sh
