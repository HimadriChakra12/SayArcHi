#!/bin/bash

# Gruvbox Nemo Setup Script for Arch Linux (Fixed)
# This script installs and configures Gruvbox GTK theme and icons for Nemo file manager

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}======================================${NC}"
echo -e "${GREEN}Gruvbox Nemo Setup for Arch Linux${NC}"
echo -e "${GREEN}======================================${NC}\n"

# Check if running on Arch
if [ ! -f /etc/arch-release ]; then
    echo -e "${RED}This script is designed for Arch Linux${NC}"
    exit 1
fi

# Install dependencies
echo -e "${YELLOW}Installing dependencies...${NC}"
sudo pacman -S --needed --noconfirm git wget unzip

# Create directories
mkdir -p ~/.themes
mkdir -p ~/.icons
mkdir -p ~/.config/gtk-3.0
mkdir -p ~/.config/gtk-4.0

# Ask user for theme variant
echo -e "\n${YELLOW}Select theme variant:${NC}"
echo "1) Gruvbox-Dark-BL (Dark theme - recommended)"
echo "2) Gruvbox-Light-BL (Light theme)"
read -p "Enter choice [1-2]: " theme_choice

case $theme_choice in
    2)
        THEME_NAME="Gruvbox-Light-BL"
        ICON_THEME="Gruvbox-Plus-Light"
        DARK_MODE=false
        ;;
    *)
        THEME_NAME="Gruvbox-Dark-BL"
        ICON_THEME="Gruvbox-Plus-Dark"
        DARK_MODE=true
        ;;
esac

# Download and install Gruvbox GTK theme
echo -e "\n${YELLOW}Installing Gruvbox GTK theme...${NC}"
TEMP_DIR=$(mktemp -d)
cd "$TEMP_DIR"

# Clone the repository
if git clone https://github.com/Fausto-Korpsvart/Gruvbox-GTK-Theme.git; then
    cd Gruvbox-GTK-Theme
    
    # Try different possible locations
    if [ -d "themes/$THEME_NAME" ]; then
        cp -r "themes/$THEME_NAME" ~/.themes/
        echo -e "${GREEN}✓ GTK theme installed from themes/$THEME_NAME${NC}"
    elif [ -d "$THEME_NAME" ]; then
        cp -r "$THEME_NAME" ~/.themes/
        echo -e "${GREEN}✓ GTK theme installed from $THEME_NAME${NC}"
    else
        # List available themes for debugging
        echo -e "${YELLOW}Available themes in repository:${NC}"
        find . -maxdepth 2 -type d -name "*Gruvbox*" | head -10
        
        # Try to find any Gruvbox dark theme
        FOUND_THEME=$(find . -maxdepth 2 -type d -name "*Gruvbox*Dark*" -o -name "*gruvbox*dark*" | head -1)
        if [ -n "$FOUND_THEME" ]; then
            THEME_DIR=$(basename "$FOUND_THEME")
            cp -r "$FOUND_THEME" ~/.themes/"$THEME_NAME"
            echo -e "${GREEN}✓ GTK theme installed from $THEME_DIR${NC}"
        else
            echo -e "${RED}Could not find theme automatically. Trying manual installation...${NC}"
        fi
    fi
else
    echo -e "${RED}Failed to clone repository${NC}"
fi

# Alternative: Try installing from AUR if git clone failed
if [ ! -d ~/.themes/"$THEME_NAME" ]; then
    echo -e "\n${YELLOW}Trying alternative installation method...${NC}"
    
    # Check if yay is installed
    if command -v yay &> /dev/null; then
        echo -e "${YELLOW}Installing via AUR...${NC}"
        yay -S --noconfirm gruvbox-material-gtk-theme-git || true
    else
        echo -e "${YELLOW}Manual installation required.${NC}"
        echo -e "Please visit: https://github.com/Fausto-Korpsvart/Gruvbox-GTK-Theme"
        echo -e "And manually install the theme to ~/.themes/$THEME_NAME"
    fi
fi

# Download and install Gruvbox icon theme
echo -e "\n${YELLOW}Installing Gruvbox icon theme...${NC}"
cd "$TEMP_DIR"

if git clone https://github.com/SylEleuth/gruvbox-plus-icon-pack.git; then
    cd gruvbox-plus-icon-pack
    
    # Check if install script exists
    if [ -f "install.sh" ]; then
        chmod +x install.sh
        ./install.sh -d ~/.icons 2>&1 | grep -v "^cp:" || true
        echo -e "${GREEN}✓ Icon theme installed${NC}"
    else
        # Manual copy
        if [ -d "Gruvbox-Plus-Dark" ]; then
            cp -r Gruvbox-Plus-* ~/.icons/
            echo -e "${GREEN}✓ Icon themes copied manually${NC}"
        fi
    fi
else
    echo -e "${YELLOW}Could not clone icon theme. Skipping...${NC}"
fi

# Configure GTK settings
echo -e "\n${YELLOW}Configuring GTK settings...${NC}"

# Create GTK 3.0 settings
cat > ~/.config/gtk-3.0/settings.ini << EOF
[Settings]
gtk-theme-name=$THEME_NAME
gtk-icon-theme-name=$ICON_THEME
gtk-font-name=Sans 10
gtk-cursor-theme-name=Adwaita
gtk-cursor-theme-size=24
gtk-toolbar-style=GTK_TOOLBAR_BOTH_HORIZ
gtk-toolbar-icon-size=GTK_ICON_SIZE_LARGE_TOOLBAR
gtk-button-images=0
gtk-menu-images=0
gtk-enable-event-sounds=1
gtk-enable-input-feedback-sounds=0
gtk-xft-antialias=1
gtk-xft-hinting=1
gtk-xft-hintstyle=hintslight
gtk-xft-rgba=rgb
gtk-application-prefer-dark-theme=$DARK_MODE
EOF

# Create GTK 4.0 settings
cat > ~/.config/gtk-4.0/settings.ini << EOF
[Settings]
gtk-theme-name=$THEME_NAME
gtk-icon-theme-name=$ICON_THEME
gtk-font-name=Sans 10
gtk-cursor-theme-name=Adwaita
gtk-cursor-theme-size=24
gtk-application-prefer-dark-theme=$DARK_MODE
EOF

echo -e "${GREEN}✓ GTK settings configured${NC}"

# Configure gsettings for various desktop environments
echo -e "\n${YELLOW}Applying theme via gsettings...${NC}"

# For GNOME/Cinnamon
gsettings set org.gnome.desktop.interface gtk-theme "$THEME_NAME" 2>/dev/null || true
gsettings set org.gnome.desktop.interface icon-theme "$ICON_THEME" 2>/dev/null || true
gsettings set org.cinnamon.desktop.interface gtk-theme "$THEME_NAME" 2>/dev/null || true
gsettings set org.cinnamon.desktop.interface icon-theme "$ICON_THEME" 2>/dev/null || true

# For XFCE
xfconf-query -c xsettings -p /Net/ThemeName -s "$THEME_NAME" 2>/dev/null || true
xfconf-query -c xsettings -p /Net/IconThemeName -s "$ICON_THEME" 2>/dev/null || true

# For MATE
gsettings set org.mate.interface gtk-theme "$THEME_NAME" 2>/dev/null || true
gsettings set org.mate.interface icon-theme "$ICON_THEME" 2>/dev/null || true

echo -e "${GREEN}✓ Theme applied via gsettings${NC}"

# Verify installation
echo -e "\n${YELLOW}Verifying installation...${NC}"
if [ -d ~/.themes/"$THEME_NAME" ]; then
    echo -e "${GREEN}✓ GTK theme found in ~/.themes/$THEME_NAME${NC}"
else
    echo -e "${RED}✗ GTK theme not found${NC}"
    echo -e "${YELLOW}Available themes:${NC}"
    ls -1 ~/.themes/ 2>/dev/null || echo "No themes installed"
fi

if [ -d ~/.icons/"$ICON_THEME" ]; then
    echo -e "${GREEN}✓ Icon theme found in ~/.icons/$ICON_THEME${NC}"
else
    echo -e "${YELLOW}! Icon theme not found (this is optional)${NC}"
fi

# Restart Nemo
echo -e "\n${YELLOW}Restarting Nemo...${NC}"
if pgrep -x "nemo" > /dev/null; then
    nemo -q 2>/dev/null || killall nemo 2>/dev/null || true
    sleep 1
    nemo &>/dev/null & disown
    echo -e "${GREEN}✓ Nemo restarted${NC}"
else
    echo -e "${YELLOW}Nemo is not running. Start it manually to see changes.${NC}"
fi

echo -e "${GREEN}Forcing Dark Gruvbox Theme for Nemo${NC}\n"

# Kill any running Nemo instances
echo -e "${YELLOW}Stopping Nemo...${NC}"
killall nemo 2>/dev/null || true
sleep 1

# Set dark theme preference
echo -e "${YELLOW}Configuring dark theme...${NC}"

# Create/update GTK 3.0 settings with dark theme
mkdir -p ~/.config/gtk-3.0
cat > ~/.config/gtk-3.0/settings.ini << 'EOF'
[Settings]
gtk-application-prefer-dark-theme=1
gtk-theme-name=Adwaita-dark
gtk-icon-theme-name=Adwaita
gtk-font-name=Sans 10
gtk-cursor-theme-name=Adwaita
gtk-cursor-theme-size=24
gtk-toolbar-style=GTK_TOOLBAR_BOTH_HORIZ
gtk-toolbar-icon-size=GTK_ICON_SIZE_LARGE_TOOLBAR
gtk-button-images=0
gtk-menu-images=0
gtk-enable-event-sounds=1
gtk-enable-input-feedback-sounds=0
gtk-xft-antialias=1
gtk-xft-hinting=1
gtk-xft-hintstyle=hintslight
gtk-xft-rgba=rgb
EOF

# Create GTK 4.0 settings
mkdir -p ~/.config/gtk-4.0
cat > ~/.config/gtk-4.0/settings.ini << 'EOF'
[Settings]
gtk-application-prefer-dark-theme=1
gtk-theme-name=Adwaita-dark
gtk-icon-theme-name=Adwaita
gtk-font-name=Sans 10
EOF

# Apply via gsettings
echo -e "${YELLOW}Applying settings via gsettings...${NC}"
gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita-dark' 2>/dev/null || true
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' 2>/dev/null || true
gsettings set org.cinnamon.desktop.interface gtk-theme 'Adwaita-dark' 2>/dev/null || true

# Set environment variable for dark theme
echo -e "${YELLOW}Setting dark theme environment variable...${NC}"
export GTK_THEME=Adwaita:dark

# Add to shell profile if not already there
if ! grep -q "GTK_THEME=Adwaita:dark" ~/.bashrc 2>/dev/null; then
    echo 'export GTK_THEME=Adwaita:dark' >> ~/.bashrc
    echo -e "${GREEN}Added GTK_THEME to ~/.bashrc${NC}"
fi

# Now check if Gruvbox theme exists and apply it
echo -e "\n${YELLOW}Checking for Gruvbox theme...${NC}"
if [ -d ~/.themes/Gruvbox-Dark-BL ] || [ -d ~/.themes/Gruvbox-Dark ]; then
    GRUVBOX_THEME=""
    if [ -d ~/.themes/Gruvbox-Dark-BL ]; then
        GRUVBOX_THEME="Gruvbox-Dark-BL"
    elif [ -d ~/.themes/Gruvbox-Dark ]; then
        GRUVBOX_THEME="Gruvbox-Dark"
    fi
    
    if [ -n "$GRUVBOX_THEME" ]; then
        echo -e "${GREEN}Found Gruvbox theme: $GRUVBOX_THEME${NC}"
        
        # Update settings to use Gruvbox
        cat > ~/.config/gtk-3.0/settings.ini << EOF
[Settings]
gtk-application-prefer-dark-theme=1
gtk-theme-name=$GRUVBOX_THEME
gtk-icon-theme-name=Gruvbox-Plus-Dark
gtk-font-name=Sans 10
gtk-cursor-theme-name=Adwaita
gtk-cursor-theme-size=24
gtk-toolbar-style=GTK_TOOLBAR_BOTH_HORIZ
gtk-toolbar-icon-size=GTK_ICON_SIZE_LARGE_TOOLBAR
gtk-button-images=0
gtk-menu-images=0
gtk-xft-antialias=1
gtk-xft-hinting=1
gtk-xft-hintstyle=hintslight
gtk-xft-rgba=rgb
EOF

        cat > ~/.config/gtk-4.0/settings.ini << EOF
[Settings]
gtk-application-prefer-dark-theme=1
gtk-theme-name=$GRUVBOX_THEME
gtk-icon-theme-name=Gruvbox-Plus-Dark
gtk-font-name=Sans 10
EOF

        gsettings set org.gnome.desktop.interface gtk-theme "$GRUVBOX_THEME" 2>/dev/null || true
        gsettings set org.gnome.desktop.interface icon-theme "Gruvbox-Plus-Dark" 2>/dev/null || true
        export GTK_THEME="$GRUVBOX_THEME"
        
        # Update .bashrc
        sed -i 's/GTK_THEME=.*/GTK_THEME='$GRUVBOX_THEME'/' ~/.bashrc 2>/dev/null || true
    fi
else
    echo -e "${YELLOW}Gruvbox theme not found, using Adwaita-dark${NC}"
    echo -e "${YELLOW}To install Gruvbox, the previous script needs to complete successfully${NC}"
fi

# Create a Nemo launcher script with dark theme
mkdir -p ~/bin
cat > ~/bin/nemo-dark << 'EOFSCRIPT'
#!/bin/bash
export GTK_THEME=Adwaita:dark
exec /usr/bin/nemo "$@"
EOFSCRIPT

chmod +x ~/bin/nemo-dark

echo -e "\n${GREEN}✓ Dark theme configured${NC}"
echo -e "${GREEN}✓ Created dark theme launcher at ~/bin/nemo-dark${NC}"

# Restart Nemo with dark theme
echo -e "\n${YELLOW}Starting Nemo with dark theme...${NC}"
GTK_THEME=Adwaita:dark nemo &>/dev/null & disown

echo -e "\n${GREEN}======================================${NC}"
echo -e "${GREEN}Dark Theme Applied!${NC}"
echo -e "${GREEN}======================================${NC}"
echo -e "\n${YELLOW}If Nemo is still light themed:${NC}"
echo -e "1. Close all Nemo windows"
echo -e "2. Run: ${GREEN}GTK_THEME=Adwaita:dark nemo${NC}"
echo -e "3. Or use the launcher: ${GREEN}~/bin/nemo-dark${NC}"
echo -e "4. Log out and log back in for permanent effect"
echo -e "\n${YELLOW}Current GTK theme:${NC}"
gsettings get org.gnome.desktop.interface gtk-theme 2>/dev/null || echo "Could not read theme setting"
echo ""

# Cleanup
echo -e "\n${YELLOW}Cleaning up temporary files...${NC}"
cd ~
rm -rf "$TEMP_DIR"

echo -e "\n${GREEN}======================================${NC}"
echo -e "${GREEN}Installation Complete!${NC}"
echo -e "${GREEN}======================================${NC}"
echo -e "\nGruvbox configuration has been applied."
echo -e "\n${YELLOW}If you don't see changes immediately:${NC}"
echo -e "1. Log out and log back in (recommended)"
echo -e "2. Or run: ${YELLOW}nemo -q && nemo &${NC}"
echo -e "3. Or restart your desktop session"
echo -e "\nConfiguration:"
echo -e "  Theme: ${GREEN}$THEME_NAME${NC}"
echo -e "  Icons: ${GREEN}$ICON_THEME${NC}"
echo -e "  Config: ${GREEN}~/.config/gtk-3.0/settings.ini${NC}\n"

# Show current GTK theme
echo -e "${YELLOW}Current GTK theme setting:${NC}"
gsettings get org.gnome.desktop.interface gtk-theme 2>/dev/null || echo "Could not read gsettings"
