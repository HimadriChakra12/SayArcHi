echo "

███████╗ █████╗ ██╗   ██╗ █████╗ ██████╗  ██████╗██╗  ██╗██╗
██╔════╝██╔══██╗╚██╗ ██╔╝██╔══██╗██╔══██╗██╔════╝██║  ██║██║
███████╗███████║ ╚████╔╝ ███████║██████╔╝██║     ███████║██║
╚════██║██╔══██║  ╚██╔╝  ██╔══██║██╔══██╗██║     ██╔══██║██║
███████║██║  ██║   ██║   ██║  ██║██║  ██║╚██████╗██║  ██║██║
╚══════╝╚═╝  ╚═╝   ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝╚═╝
                                                            
Wanna Start The Script? Press [Enter] to continue...
"

read -r

sudo pacman -S --noconfirm ly
sudo systemctl enable ly.service
echo "Ly installed and enabled."

sudo pacman -S --needed base-devel git

mkdir ~/temp

if command -v pikaur >/dev/null; then
    echo "pikaur is already installed."
else
    echo "pikaur is not installed. Installing..."
    git clone https://aur.archlinux.org/pikaur.git ~/temp/pikaur
    cd ~/temp/pikaur
    makepkg -fsri --noconfirm
    echo "Installed pikaur"
fi

if command -v yay >/dev/null; then
    echo "yay is already installed."
else
    echo "yay is not installed. Installing..."
    git clone https://aur.archlinux.org/yay-bin.git ~/temp/yay
    cd ~/temp/yay
    makepkg -si --noconfirm
    echo "Installed yay"
fi

rm -r -f ~/temp

echo "Installing Packages"
langs=(
    "rust"
    "cmake"
    "make"
    "gcc"
    "golang"
)
shell=(
    "ranger"
    "curl"
    "github-cli"
    "lazygit"
    "neovim"
    "tmux"
    "cat"
    "unzip"
)
i3=(
    "wezterm"
    "acpi"
    "arandr"
    "arc-gtk-theme-eos"
    "archlinux-xdg-menu"
    "awesome-terminal-fonts"
    "dex"
    "dmenu"
    "dunst"
    "eos-settings-i3wm"
    "endeavouros-xfce4-terminal-colors"
    "eos-lightdm-slick-theme"
    "eos-qogir-icons"
    "feh"
    "galculator"
    "gvfs"
    "gvfs-afc"
    "gvfs-gphoto2"
    "gvfs-mtp"
    "gvfs-nfs"
    "gvfs-smb"
    "i3-wm"
    "i3blocks"
    "i3lock"
    "i3status"
    "jq"
    "nwg-look"
    "mpv"
    "network-manager-applet"
    "numlockx"
    "playerctl"
    "polkit-gnome"
    "rofi"
    "scrot"
    "sysstat"
    "thunar-volman"
    "tumbler"
    "unzip"
    "xarchiver"
    "xbindkeys"
    "xdg-user-dirs-gtk"
    "xed"
    "xfce4-terminal"
    "xorg-xbacklight"
    "xorg-xdpyinfo"
    "xss-lock"
    "zip"
    "xorg-server"
    "xorg-xinit"
    "xorg-xauth"
    "xorg-xrandr"
    "xorg-fonts-misc"
    "xorg-xsetroot"
    "xterm"
    "i3-wm"
    "i3status"
    "dmenu"
    "dunst"
    "nemo"
    "rofi"
)
packages=(
    "firefox"
    "qimgv"
    "mpv"
    "qemu"
    "spotify"
    "jdownloader2"
    "qbittorrent"
)


echo "

 |   _. ._   _   _ 
 |_ (_| | | (_| _> 
             _|    
--------------------
"
yay -S --noconfirm "${langs[@]}"
echo "
  __             
 (_  |_   _  | | 
 __) | | (/_ | | 
-------------------
"
yay -S --noconfirm "${shell[@]}"
echo "
   _  
 o _) 
 | _) 
-------      
"
yay -S --noconfirm "${i3[@]}"
echo "
  _                   
 / \ _|_ |_   _  ._ _ 
 \_/  |_ | | (/_ | _> 
-----------------------
"
yay -S --noconfirm "${packages[@]}"

echo "
                _            
    _|  _ _|_ _|_ o |  _   _ 
 o (_| (_) |_  |  | | (/_ _> 
------------------------------
"

git clone https://github.com/HimadriChakra12/.dotfiles.git ~/.dotfiles

dotfiles=(
  "$HOME/.dotfiles/i3:$HOME/.config/i3"
  "$HOME/.dotfiles/rofi:$HOME/.config/rofi"
  "$HOME/.dotfiles/dunst:$HOME/.config/dunst"
  "$HOME/.dotfiles/gh:$HOME/.config/gh"
  "$HOME/.dotfiles/mpv:$HOME/.config/mpv"
  "$HOME/.dotfiles/nvim:$HOME/.config/nvim"
  "$HOME/.dotfiles/qimgv:$HOME/.config/qimgv"
  "$HOME/.dotfiles/wezterm:$HOME/.config/wezterm"
  "$HOME/.dotfiles/.bashrc:$HOME/.bashrc"
  "$HOME/.dotfiles/.tmux.conf:$HOME/.tmux.conf"
)

echo "Linking dotfiles..."
for entry in "${dotfiles[@]}"; do
  src="${entry%%:*}"
  tgt="${entry##*:}"
  echo "Linking $src → $tgt"
  ln -sf "$src" "$tgt"
done

echo "
Defaulting Apps
---------------
"

echo "Creating ~/.xinitrc if missing..."
if [ ! -f ~/.xinitrc ]; then
  echo "exec i3" > ~/.xinitrc
  echo "~/.xinitrc created with 'exec i3'"
else
  echo "~/.xinitrc already exists. Make sure it has 'exec i3'"
fi
echo "Creating local .desktop entries if missing..."
mkdir -p ~/.local/share/applications
if [ ! -f ~/.local/share/applications/firefox.desktop ]; then
  echo "Creating firefox.desktop..."
  cat > ~/.local/share/applications/firefox.desktop <<EOF
[Desktop Entry]
Name=Firefox
Exec=firefox %u
Type=Application
Icon=firefox
Terminal=false
Categories=Network;WebBrowser;
MimeType=x-scheme-handler/http;x-scheme-handler/https;
StartupNotify=true
EOF
fi
if [ ! -f ~/.local/share/applications/nemo.desktop ]; then
  echo "Creating nemo.desktop..."
  cat > ~/.local/share/applications/nemo.desktop <<EOF
[Desktop Entry]
Name=Nemo
Exec=nemo %U
Type=Application
Icon=folder
Terminal=false
Categories=System;FileTools;FileManager;
MimeType=inode/directory;
EOF
fi
echo "Setting default applications..."
xdg-settings set default-web-browser firefox.desktop
echo "Firefox set as default browser"
echo "Setting Qimgv as default image viewer..."
for mime in image/jpeg image/png image/gif image/webp image/svg+xml; do
  xdg-mime default qimgv.desktop "$mime"
done
echo "Setting MPV as default video player..."
for mime in video/mp4 video/x-matroska video/x-msvideo video/webm; do
  xdg-mime default mpv.desktop "$mime"
done
echo "Setting Rhythmbox as default music player..."
for mime in audio/mpeg audio/x-wav audio/ogg audio/flac; do
  xdg-mime default rhythmbox.desktop "$mime"
done
xdg-mime default nemo.desktop inode/directory
xdg-settings set default-file-manager nemo.desktop
echo "Nemo set as default file manager"
echo "All defaults configured successfully!"
