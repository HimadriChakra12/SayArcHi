#!/bin/bash
set -e

echo "==> Arch Linux Master Installer (Base + User Setup)"
lsblk -d -o NAME,SIZE,MODEL
# 1. Prompt for values
read -rp "Enter target disk (e.g. /dev/sda): " DISK
read -rp "Enter hostname: " HOSTNAME
read -rp "Enter new username: " USERNAME
while true; do
  read -rsp "Enter password for $USERNAME: " PASSWORD
  echo
  read -rsp "Confirm password: " PASSWORD2
  echo
  if [[ "$PASSWORD" == "$PASSWORD2" ]]; then
    echo "Passwords match!"
    break
  else
    echo "Passwords do not match. Try again."
  fi
done

# 2. Partition + Format
echo "==> Partitioning $DISK..."
sgdisk -Z "$DISK"
sgdisk -n1:0:+512M -t1:ef00 "$DISK"
sgdisk -n2:0:0 -t2:8300 "$DISK"

mkfs.fat -F32 "${DISK}1"
mkfs.ext4 "${DISK}2"

# 3. Mount
mount "${DISK}2" /mnt
mkdir -p /mnt/boot
mount "${DISK}1" /mnt/boot

# 4. Install base system
echo "==> Installing base packages..."
pacstrap /mnt base base-devel linux linux-firmware bash sudo networkmanager efibootmgr git

# 5. Generate fstab
genfstab -U /mnt >> /mnt/etc/fstab

# 6. Chroot configuration
echo "==> Configuring system in chroot..."
arch-chroot /mnt /bin/bash <<EOF
ln -sf /usr/share/zoneinfo/Asia/Dhaka /etc/localtime
hwclock --systohc
echo "$HOSTNAME" > /etc/hostname

sed -i 's/#en_US.UTF-8/en_US.UTF-8/' /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf

echo "root:$PASSWORD" | chpasswd

useradd -m -G wheel,audio,video -s /bin/bash $USERNAME
echo "$USERNAME:$PASSWORD" | chpasswd
sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

bootctl install
UUID=\$(blkid -s UUID -o value ${DISK}2)
cat <<LOADER > /boot/loader/entries/arch.conf
title   Arch Linux
linux   /vmlinuz-linux
initrd  /initramfs-linux.img
options root=UUID=\$UUID rw
LOADER

echo "default arch" > /boot/loader/loader.conf

systemctl enable NetworkManager
EOF

# 7. Download setup_desktop.sh to user's home
echo "==> Downloading setup_desktop.sh..."
curl -L https://raw.githubusercontent.com/HimadriChakra12/Sayarchi/main/sayarchi.sh -o /mnt/home/$USERNAME/setup_desktop.sh
arch-chroot /mnt chown $USERNAME:$USERNAME /home/$USERNAME/sayarchi.sh
arch-chroot /mnt chmod +x /home/$USERNAME/sayarchi.sh

echo "==> Cloning dotfiles..."
arch-chroot /mnt /bin/bash -c "cd /home/$USERNAME && git clone https://github.com/HimadriChakra12/.dotfiles.git .dotfiles && chown -R $USERNAME:$USERNAME .dotfiles"

echo "==> DONE! Reboot and log in as '$USERNAME', then run: ./setup_desktop.sh"
