#!/usr/bin/env bash
# 01-install-wine-base.sh
# Base Wine installation with Vulkan support
set -euo pipefail

echo "🍷 Wine Base Installer"
echo "====================="

# ------------------------
# Detect Package Manager
# ------------------------
detect_pkg_manager() {
  for pm in pacman apt dnf zypper; do
    command -v "$pm" >/dev/null && echo "$pm" && return
  done
  echo "unknown"
}

# ------------------------
# Detect GPU
# ------------------------
detect_gpu() {
  if lspci 2>/dev/null | grep -E "VGA|3D" | head -n1 | grep -qi nvidia; then
    echo "nvidia"
  elif lspci 2>/dev/null | grep -qi amd; then
    echo "amd"
  elif lspci 2>/dev/null | grep -qi intel; then
    echo "intel"
  else
    echo "unknown"
  fi
}

# ------------------------
# Install Dependencies
# ------------------------
install_deps() {
  local pm gpu
  pm="$(detect_pkg_manager)"
  gpu="$(detect_gpu)"
  
  echo "Package manager: $pm"
  echo "Detected GPU: $gpu"
  echo
  
  case "$pm" in
    pacman)
      echo "Installing Wine + dependencies for Arch..."
      sudo pacman -Syu --needed --noconfirm \
        wine-staging \
        winetricks \
        lib32-mesa \
        vulkan-icd-loader \
        lib32-vulkan-icd-loader
      
      case "$gpu" in
        amd)
          sudo pacman -S --needed --noconfirm \
            vulkan-radeon lib32-vulkan-radeon \
            lib32-mesa-vdpau
          ;;
        nvidia)
          sudo pacman -S --needed --noconfirm \
            nvidia-utils lib32-nvidia-utils \
            vulkan-icd-loader lib32-vulkan-icd-loader
          ;;
        intel)
          sudo pacman -S --needed --noconfirm \
            vulkan-intel lib32-vulkan-intel
          ;;
      esac
      
      # Optional performance tools
      sudo pacman -S --needed --noconfirm gamemode lib32-gamemode || true
      ;;
      
    apt)
      echo "Installing Wine + dependencies for Debian/Ubuntu..."
      sudo dpkg --add-architecture i386 || true
      sudo apt update
      sudo apt install -y \
        wine64 wine32 winetricks \
        libvulkan1 libvulkan1:i386 \
        mesa-vulkan-drivers mesa-vulkan-drivers:i386
      
      case "$gpu" in
        nvidia)
          sudo apt install -y nvidia-vulkan-icd nvidia-vulkan-icd:i386 || true
          ;;
      esac
      
      sudo apt install -y gamemode || true
      ;;
      
    dnf)
      echo "Installing Wine + dependencies for Fedora..."
      sudo dnf install -y \
        wine winetricks \
        vulkan-loader vulkan-loader.i686 \
        mesa-vulkan-drivers mesa-vulkan-drivers.i686
      
      case "$gpu" in
        nvidia)
          sudo dnf install -y xorg-x11-drv-nvidia-libs.i686 || true
          ;;
      esac
      
      sudo dnf install -y gamemode || true
      ;;
      
    zypper)
      echo "Installing Wine + dependencies for openSUSE..."
      sudo zypper install -y \
        wine winetricks \
        libvulkan1 libvulkan1-32bit
      
      sudo zypper install -y gamemode || true
      ;;
      
    *)
      echo "❌ Unknown package manager!"
      echo "Please install manually:"
      echo "  - Wine (wine-staging preferred)"
      echo "  - winetricks"
      echo "  - Vulkan drivers for your GPU"
      exit 1
      ;;
  esac
}

# ------------------------
# Verify Installation
# ------------------------
verify_installation() {
  echo
  echo "Verifying installation..."
  
  if ! command -v wine >/dev/null; then
    echo "❌ Wine not found!"
    exit 1
  fi
  
  if ! command -v winetricks >/dev/null; then
    echo "❌ winetricks not found!"
    exit 1
  fi
  
  echo "✅ Wine version: $(wine --version)"
  echo "✅ winetricks installed"
  
  if command -v vulkaninfo >/dev/null; then
    echo "✅ Vulkan available: $(vulkaninfo --summary 2>/dev/null | grep -i 'instance version' || echo 'present')"
  else
    echo "⚠️  vulkaninfo not found (install vulkan-tools to verify)"
  fi
}

# ------------------------
# Main
# ------------------------
main() {
  sudo -v
  install_deps
  verify_installation
  
  echo
  echo "✅ Base Wine installation complete!"
  echo "Next steps:"
  echo "  1. Run: ./02-create-wine-prefix.sh --help"
  echo "  2. Configure for gaming or Photoshop"
}

main "$@"
