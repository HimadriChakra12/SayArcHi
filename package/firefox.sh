#!/usr/bin/env bash
set -euo pipefail

# -----------------------------
# Install Firefox (Arch only)
# -----------------------------
if ! command -v firefox &>/dev/null; then
    yay -S --noconfirm firefox
fi

read -rp "Wanna Add The Dots? [y/n]: " ch
[[ "$ch" != "y" ]] && exit 0

read -rp "What's the path of your Firefox profile: " path

if [[ ! -d "$path" ]]; then
    echo "Invalid Firefox profile path"
    exit 1
fi

# Remove old chrome folder if exists
if [[ -d "$path/chrome" ]]; then
    rm -rf "$path/chrome"
fi

cd $path
echo "
Which Theme You want to install:
1. Him-Ultima
2. Say-O-Fox
3. Dot
"
read -rp "Choose [1-3]: " opt

case "$opt" in
    1)
        echo "Installing Him-Ultima..."
        curl -fsSL \
          https://raw.githubusercontent.com/HimadriChakra12/HIM-ULTIMA/main/ffultima.sh \
          | bash
        ;;
    2)
        echo "Say-O-Fox is still under development"
        ;;
    3)
        echo "Installing Dot theme..."
        mkdir -p "$path/chrome"

        declare -A dotfiles=(
            ["$HOME/.dotfiles/firefox/userChrome.css"]="$path/chrome/userChrome.css"
            ["$HOME/.dotfiles/firefox/user.js"]="$path/user.js"
        )

        for src in "${!dotfiles[@]}"; do
            tgt="${dotfiles[$src]}"
            echo "Linking $src → $tgt"
            rm -rf "$tgt"
            ln -sf "$src" "$tgt"
        done
        ;;
    *)
        echo "Invalid choice"
        exit 0
        ;;
esac

# -----------------------------
# Firefox policies (Arch)
# -----------------------------
if [[ -f "$HOME/.dotfiles/firefox/policies.json" ]]; then
    sudo mkdir -p /usr/lib/firefox/distribution
    sudo cp "$HOME/.dotfiles/firefox/policies.json" \
        /usr/lib/firefox/distribution/
fi

# -----------------------------
# Desktop entry
# -----------------------------
echo "Ensuring local .desktop entry exists..."
mkdir -p ~/.local/share/applications

DESKTOP_FILE="$HOME/.local/share/applications/firefox.desktop"

if [[ ! -f "$DESKTOP_FILE" ]]; then
    cat > "$DESKTOP_FILE" <<EOF
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

xdg-settings set default-web-browser firefox.desktop
echo "Firefox set as default browser ✅"
