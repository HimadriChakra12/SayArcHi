#!/bin/bash
set -e

echo "==> Installing desktop environment and applications..."

if [[ ! -d pikaur ]]; then
sudo pacman -S --needed base-devel git
git clone https://aur.archlinux.org/pikaur.git
cd pikaur
makepkg -fsri
fi

if [[ ! -d yay ]]; then
sudo pacman -S --needed git base-devel
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si
fi

# Define package list
core_pkgs=(
  xorg xorg-xinit i3-gaps i3status dmenu
  pipewire pipewire-pulse wireplumber alsa-utils
  wezterm nemo firefox mpv bash wine qimgv
  vulkan-intel vulkan-radeon mesa lib32-mesa lib32-vulkan-*
  git base-devel wget gnome-keyring libsecret
  xfce4-clipman flameshot
)

yay -Syu --noconfirm "${core_pkgs[@]}"

echo "==> Installing Microsoft Edge browser..."
edge_pkg="microsoft-edge-stable-*.pkg.tar.zst"
wget https://packages.microsoft.com/repos/edge/pool/main/m/microsoft-edge-stable/$edge_pkg
sudo pacman -U --noconfirm $edge_pkg
rm $edge_pkg

echo "==> Installing AUR helpers..."

cd ~
if [[ ! -d pikaur ]]; then
sudo pacman -S --needed base-devel git
git clone https://aur.archlinux.org/pikaur.git
cd pikaur
makepkg -fsri
fi

cd ~
if [[ ! -d yay ]]; then
sudo pacman -S --needed git base-devel
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si
fi

echo "==> Setting up i3 config..."
mkdir -p ~/.config/i3
config_file=~/.config/i3/config

autostart_cmds=(
  "exec --no-startup-id xfce4-clipman &"
  "exec --no-startup-id flameshot &"
)
for cmd in "${autostart_cmds[@]}"; do
  if ! grep -Fxq "$cmd" "$config_file" 2>/dev/null; then
    echo "$cmd" >> "$config_file"
  fi
done

bind_cmd="bindsym Print exec flameshot gui"
if ! grep -Fxq "$bind_cmd" "$config_file" 2>/dev/null; then
  echo "$bind_cmd" >> "$config_file"
fi
cd ~
if [[ ! -d dotfiles ]]; then
  git clone https://github.com/HimadriChakra12/.dotfiles.git .dotfiles
  cd ~/.dotfiles
fi

cd dotfiles
if [[ -f install.sh ]]; then
  bash dotfiles.sh
fi

echo "exec i3" > ~/.xinitrc

# Define your dotfiles as source→target pairs

echo "==> DONE! Run 'startx' to launch i3."

