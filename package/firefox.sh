set -e

yay -S --noconfirm firefox

read -p "Whats the path O'your Firefox Profile: " path
read -p "
Which Theme You want to install:
    1. Him-Ultima
    2. Say-O-Fox
    3. Dot
" opt

if [[ "$opt" == 1 ]]; then
    curl -sL "https://raw.githubusercontent.com/HimadriChakra12/HIM-ULTIMA/refs/heads/main/ffultima.sh" | bash
elif [[ "$opt" == 2 ]]; then
    echo "Still In building"
else
    mkdir -p "$path/chrome"
    dotfiles=(
        "$HOME/penboot/dotfiles/firefox/userChrome.css:$path/chrome/userChrome.css"
        "$HOME/penboot/dotfiles/firefox/user.js:$path/user.js"
    )

    echo "Linking dotfiles..."
    for entry in "${dotfiles[@]}"; do
        src="${entry%%:*}"
        tgt="${entry##*:}"
        echo "Linking $src → $tgt"
        rm "$tgt" -r
        ln -sf "$src" "$tgt"
    done

    sudo cp $HOME/penboot/dotfiles/firefox/policies.json /usr/lib/firefox/distribution
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
echo "Setting default applications..."
xdg-settings set default-web-browser firefox.desktop
echo "Firefox set as default browser"
