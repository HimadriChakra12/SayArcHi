echo "Press Enter to Install Spotify:"
read -r

yay -S --noconfirm spotify
bash <(curl -sSL https://spotx-official.github.io/run.sh)
