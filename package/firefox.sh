#!/usr/bin/env bash
set -e

yay -S --noconfirm firefox

read -p "Wanna Add The Dots? [y/n]: " ch

if [[ "$ch" == "y" ]]; then
    read -p "What's the path of your Firefox profile: " path

    echo "
Which Theme You want to install:
1. Him-Ultima
2. Say-O-Fox
3. Dot
"
    read -p "Choose [1-3]: " opt

    if [[ "$opt" == "1" ]]; then
        curl -sL "https://raw.githubusercontent.com/HimadriChakra12/HIM-ULTIMA/refs/heads/main/ffultima.sh" | bash

    elif [[ "$opt" == "2" ]]; then
        echo "Still in building"

    elif [[ "$opt" == "3" ]]; then
        mkdir -p "$path/chrome"

        dotfiles=(
            "$HOME/.dotfiles/firefox/userChrome.css:$path/chrome/userChrome.css"
            "$HOME/.dotfiles/firefox/user.js:$path/user.js"
        )

        echo "Linking dotfiles..."
        for entry in "${dotfiles[@]}"; do
            src="${entry%%:*}"
            tgt="${entry##*:}"
            echo "Linking $src → $tgt"
            rm -rf "$tgt"
            ln -sf "$src" "$tgt"
        done
    else
        exit 0
    fi
else
    exit 0
fi

sudo cp "$HOME/.dotfiles/firefox/policies.json" /usr/lib/firefox/distribution

echo "Creating local .desktop entries if missing..."
mkdir -p ~/.local/share/applications

if [[ ! -f ~/.local/share/applications/firefox.desktop ]]; then
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

xdg-settings set default-web-browser firefox.desktop
echo "Firefox set as default browser"
