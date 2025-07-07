mkdir ~/temp

sudo pacman -S --needed base-devel git

echo "Installing pikaur...."
git clone https://aur.archlinux.org/pikaur.git ~/temp/pikaur
cd ~/temp/pikaur
makepkg -fsri
echo "Installed pikaur...."

echo "Installing yay...."
git clone https://aur.archlinux.org/yay-bin.git ~/temp/yay
cd ~/temp/yay
makepkg -si
echo "Installed yay...."

rm -r ~/temp
