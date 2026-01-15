docker=(
    "docker"
    "docker-compose"
)

echo -e "${GREEN}Installing Docker & Plugins!${NC}"
yay -S --noconfirm "${docker[@]}"
#!/bin/bash
set -e

USER_NAME="${SUDO_USER:-$USER}"

echo "Configuring Docker access for user: $USER_NAME"

# Must be run as root
if [[ $EUID -ne 0 ]]; then
    echo "Please run this script with sudo:"
    echo "  sudo $0"
    exit 1
fi

# 1. Ensure docker group exists
if getent group docker >/dev/null; then
    echo "✔ docker group already exists"
else
    echo "➕ Creating docker group"
    groupadd docker
fi

# 2. Check if user is already in docker group
if id -nG "$USER_NAME" | grep -qw docker; then
    echo "✔ User '$USER_NAME' is already in the docker group"
else
    echo "➕ Adding user '$USER_NAME' to docker group"
    usermod -aG docker "$USER_NAME"
fi

echo
echo "✅ Docker permissions configured successfully."
echo
echo "⚠ IMPORTANT:"
echo "Log out and log back in OR run:"
echo "  newgrp docker"
echo
echo "Then verify with:"
echo "  docker ps"

