echo "in

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

sudo timedatectl set-timezone Asia/Dhaka
sudo usermod -aG tty himadri

sudo pacman -Syu
sudo pacman -S --needed base-devel git fzf
sudo pacman -S --needed flatpak

if [ -d "$HOME/sayarchi" ]; then
    cd $HOME/sayarchi
else
    git clone https://github.com/himadrichakr12/sayarchi ~/sayarchi
    cd $HOME/sayarchi
fi

echo -e "\n${GREEN}==================${NC}"
echo -e "${GREEN}Dotfiles!${NC}"
echo -e "${GREEN}==================${NC}"

git clone https://github.com/HimadriChakra12/.dotfiles.git ~/.dotfiles
bash $HOME/.dotfiles/dots.sh

git clone https://github.com/HimadriChakra12/himstart.nvim ~/.config/nvim

scripts=(
    "AUR-Helpers:$HOME/sayarchi/package/AUR.sh"
    "reflactor:$HOME/sayarchi/package/reflactor.sh"
    "ly:$HOME/sayarchi/package/ly.sh"
    "firefox:$HOME/sayarchi/package/firefox.sh"
    "pcmanfm:$HOME/sayarchi/package/pcmanfm.sh"
    "pkgback:$HOME/sayarchi/pkgback/pkgback.sh"
)

echo "Running Scripts"
for entry in "${scripts[@]}"; do
    name="${entry%%:*}"
    script="${entry##*:}"
    echo "Installing and setting up $name"
    if [[ -f "$script" ]]; then
        bash "$script"
    else
        echo "❌ Script not found: $script"
        exit 0
    fi
done

echo -e "\n${GREEN}======================================${NC}"
echo -e "${GREEN}Installing Packages!${NC}"
echo -e "${GREEN}======================================${NC}"

langs=(
    "rustup"
    "cmake"
    "make"
    "gcc"
    "golang"
    "python"
    "python-pipx"
)
shell=(
    "cmus"
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
    "starship"
    "zsh"
)
i3=(
    "i3-wm"
    "i3blocks"
    "i3lock-color"
    "i3status"
    "wlctl-bin"
    "bluetui"
    "dbus"

    "redshift"
    "flameshot"
    "wezterm"
    "mpv"
    "feh"
    "ffmpeg"
    "wf-recorder"
    "libnotify"
    "alsa-utils"

    "rofi"
    "rofi-greenclip"

    "acpi"
    "arandr"
    "arc-gtk-theme-eos"
    "archlinux-xdg-menu"
    "awesome-terminal-fonts"
    "dex"

    "dunst"

    "eos-settings-i3wm"

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

    "noto-fonts"
    "ttf-jetbrains-mono-nerd"

    "yt-dlp"

    "brightnessctl"
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
    "pavucontrol"
    "xclip"
)
packages=(
    "xdman-beta-bin"
    "qimgv"
    "ibus-avro-git"
    "mpv"
    "qemu"
    "jdownloader2"
    "qbittorrent"
    "lollypop"
    "localsend"
    "microsoft-edge-stable-bin"
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


echo "
Defaulting Apps
---------------
"

echo "Creating ~/.xinitrc if missing..."
if [ ! -f ~/.xinitrc ]; then
    echo "exec i3" >~/.xinitrc
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
echo "Setting Lollypop as default music player..."
for mime in audio/mpeg audio/x-wav audio/ogg audio/flac; do
    xdg-mime default lollypop.desktop "$mime"
done
echo "All defaults configured successfully!"
