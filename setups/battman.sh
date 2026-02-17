#!/usr/bin/env bash
set -e

echo "== Installing power management packages =="
sudo pacman -S --needed --noconfirm \
    tlp tlp-rdw thermald powertop cpupower brightnessctl

echo "== Enabling services =="
sudo systemctl enable tlp.service
sudo systemctl enable thermald.service
sudo systemctl enable cpupower.service

echo "== Starting services =="
sudo systemctl start tlp.service
sudo systemctl start thermald.service

echo "== Setting CPU governor to powersave =="
sudo sed -i "s/^#*governor=.*/governor='powersave'/" /etc/default/cpupower || \
echo "governor='powersave'" | sudo tee /etc/default/cpupower

sudo systemctl restart cpupower.service

echo "== Enabling Intel iGPU power saving =="
echo "options i915 enable_psr=1 enable_fbc=1" | \
sudo tee /etc/modprobe.d/i915-power.conf

echo "== Enabling WiFi power saving (NetworkManager) =="
sudo mkdir -p /etc/NetworkManager/conf.d
echo -e "[connection]\nwifi.powersave = 3" | \
sudo tee /etc/NetworkManager/conf.d/wifi-powersave.conf

echo "== Creating Powertop auto-tune service =="
sudo tee /etc/systemd/system/powertop.service > /dev/null <<EOF
[Unit]
Description=Powertop tunings

[Service]
Type=oneshot
ExecStart=/usr/bin/powertop --auto-tune

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl enable powertop.service

echo "== Disabling bluetooth (can re-enable if needed) =="
sudo systemctl disable bluetooth.service 2>/dev/null || true
sudo systemctl stop bluetooth.service 2>/dev/null || true

echo
echo "========================================="
echo "Battery optimization setup complete."
echo "Reboot recommended."
echo "========================================="
