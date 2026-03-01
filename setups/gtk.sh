sudo pacman -S gtk-engine-murrine

if [ ! -d $HOME/.gtk ]; then
    git clone https://github.com/Fausto-Korpsvart/Gruvbox-GTK-Theme $HOME/.gtk --depth 1
fi
cd $HOME/.gtk/themes/
bash install.sh -n Gruvhim -c dark -l --tweaks medium float outline -s compact
