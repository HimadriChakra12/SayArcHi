packages=(
    "firefox"
    "qimgv"
    "mpv"
    "qemu"
    "spotify"
    "jdownloader2"
    "qbittorrent"
)
echo "Suppliments"
yay -S --noconfirm "${packages[@]}"

echo "Init Spot-X Bash"
bash <(curl -sSL https://spotx-official.github.io/run.sh)
