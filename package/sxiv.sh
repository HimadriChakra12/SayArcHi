#!/bin/bash
sudo pacman -S base-devel git imlib2 libx11 libxft libxinerama libxrandr

path="$HOME/git"
sxiv="$path/hsxiv"

mkdir -p $path

if [ -d $sxiv ]; then
    cd $sxiv
    git pull
else
    git clone https://github.com/HimadriChakra12/hsxiv.git $sxiv
fi

cd $sxiv
bash install.sh

ln -s $HOME/.dotfiles/.Xresources $HOME/.Xresources
xrdb -merge ~/.Xresources

mkdir -p "$HOME/.config/sxiv"
ln -s $sxiv/exec/ $HOME/.config/sxiv/exec
