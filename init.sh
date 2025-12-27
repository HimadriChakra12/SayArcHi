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

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

sudo pacman -S --needed base-devel git

echo -e "\n${GREEN}======================================${NC}"
echo -e "${GREEN}Installing Packages!${NC}"
echo -e "${GREEN}======================================${NC}"

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
    "7zip"
    "zoxide"
    "btop"
)
i3=(
    "i3-wm"
    "i3blocks"
    "i3lock"
    "i3status"
    "impala"

    "redshift"
    "flameshot"
    "wezterm"
    "mpv"
    "feh"
    "rofi"

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

    "galculator"
    "gvfs"
    "gvfs-afc"
    "gvfs-gphoto2"
    "gvfs-mtp"
    "gvfs-nfs"
    "gvfs-smb"

    "jq"
    "nwg-look"
    "network-manager-applet"
    "numlockx"
    "playerctl"
    "polkit-gnome"
    "scrot"
    "sysstat"
    "thunar-volman"
    "tumbler"
    "zip"
    "unzip"

    "xarchiver"
    "xbindkeys"
    "xdg-user-dirs-gtk"
    "xed"
    "xfce4-terminal"
    "xorg-xbacklight"
    "xorg-xdpyinfo"
    "xss-lock"
    "xorg-server"
    "xorg-xinit"
    "xorg-xauth"
    "xorg-xrandr"
    "xorg-fonts-misc"
    "xorg-xsetroot"
    "xterm"
    "pavucontrol"
    "xclip"
)
packages=(
    "qimgv"
    "mpv"
    "qemu"
    "jdownloader2"
    "qbittorrent"
)


echo -e "\n${GREEN}======================================${NC}"
echo -e "${GREEN}Installing Language Packages!${NC}"
echo -e "${GREEN}======================================${NC}"

yay -S --noconfirm "${langs[@]}"

echo -e "\n${GREEN}======================================${NC}"
echo -e "${GREEN}Installing Shell Packages!${NC}"
echo -e "${GREEN}======================================${NC}"

yay -S --noconfirm "${shell[@]}"

echo -e "\n${GREEN}======================================${NC}"
echo -e "${GREEN}Installing i3 Packages!${NC}"
echo -e "${GREEN}======================================${NC}"

yay -S --noconfirm "${i3[@]}"

echo -e "\n${GREEN}======================================${NC}"
echo -e "${GREEN}Installing Packages!${NC}"
echo -e "${GREEN}======================================${NC}"

yay -S --noconfirm "${packages[@]}"

echo -e "\n${GREEN}==================${NC}"
echo -e "${GREEN}Dotfiles!${NC}"
echo -e "${GREEN}==================${NC}"

git clone https://github.com/HimadriChakra12/.dotfiles.git ~/.dotfiles

chmod +x ~/.dotfiles/dotfiles.sh
bash ~/.dotfiles/dotfiles.sh

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
echo "All defaults configured successfully!"
