#!/bin/bash
path="$HOME/git"
mkdir -p $path
git clone https://github.com/HimadriChakra12/sxiv.git $path/sxiv

cd $path/sxiv
bash install.sh
