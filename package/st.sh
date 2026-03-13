#!/bin/bash
sudo pacman -S base-devel git mupdf

path="$HOME/pkg"
st="$path/st"

mkdir -p $path

if [ -d $st ]; then
    cd $st
    git pull
else
    git clone https://github.com/HimadriChakra12/st.git $st
fi

cd $st
bash install.sh
