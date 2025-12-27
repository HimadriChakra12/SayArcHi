set -e 
echo -e "\n${GREEN}======================================${NC}"
echo -e "${GREEN}Installing Pikaur and Yay!${NC}"
echo -e "${GREEN}======================================${NC}"

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

rm -rf ~/temp
