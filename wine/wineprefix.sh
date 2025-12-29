#!/usr/bin/env bash
# 02-create-wine-prefix.sh
# Create and configure a Wine prefix with basic settings
set -euo pipefail

# ------------------------
# Config
# ------------------------
WINEPREFIX_DEFAULT="$HOME/.wine-custom"
WINEARCH_DEFAULT="win64"

# ------------------------
# CLI args
# ------------------------
WINEPREFIX="$WINEPREFIX_DEFAULT"
WINEARCH="$WINEARCH_DEFAULT"
PREFIX_NAME=""
OVERWRITE=0

usage() {
  cat <<EOF
Usage: $0 [OPTIONS]

Create and initialize a Wine prefix with basic configuration.

OPTIONS:
  --prefix PATH      Wine prefix path (default: $WINEPREFIX_DEFAULT)
  --arch ARCH        Architecture: win64 or win32 (default: $WINEARCH_DEFAULT)
  --name NAME        Friendly name for this prefix
  --overwrite        Overwrite existing prefix without asking
  -h, --help         Show this help

EXAMPLES:
  $0 --name photoshop --prefix ~/.wine-photoshop
  $0 --name gaming --prefix ~/.wine-games --arch win64
EOF
  exit 0
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --prefix) WINEPREFIX="$2"; shift 2 ;;
    --arch) WINEARCH="$2"; shift 2 ;;
    --name) PREFIX_NAME="$2"; shift 2 ;;
    --overwrite) OVERWRITE=1; shift ;;
    -h|--help) usage ;;
    *) echo "Unknown argument: $1"; usage ;;
  esac
done

echo "🍷 Wine Prefix Creator"
echo "====================="
echo "Prefix: $WINEPREFIX"
echo "Architecture: $WINEARCH"
[[ -n "$PREFIX_NAME" ]] && echo "Name: $PREFIX_NAME"
echo

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

get_vk_icd() {
  case "$1" in
    amd) 
      if [[ -f "/usr/share/vulkan/icd.d/radeon_icd.x86_64.json" ]]; then
        echo "/usr/share/vulkan/icd.d/radeon_icd.x86_64.json"
      elif [[ -f "/usr/share/vulkan/icd.d/radeon_icd.json" ]]; then
        echo "/usr/share/vulkan/icd.d/radeon_icd.json"
      fi
      ;;
    intel) 
      if [[ -f "/usr/share/vulkan/icd.d/intel_icd.x86_64.json" ]]; then
        echo "/usr/share/vulkan/icd.d/intel_icd.x86_64.json"
      elif [[ -f "/usr/share/vulkan/icd.d/intel_icd.json" ]]; then
        echo "/usr/share/vulkan/icd.d/intel_icd.json"
      fi
      ;;
    nvidia) 
      if [[ -f "/usr/share/vulkan/icd.d/nvidia_icd.json" ]]; then
        echo "/usr/share/vulkan/icd.d/nvidia_icd.json"
      fi
      ;;
  esac
}

# ------------------------
# Check Existing Prefix
# ------------------------
if [[ -d "$WINEPREFIX" ]]; then
  if [[ "$OVERWRITE" -eq 0 ]]; then
    read -rp "⚠️  Prefix exists. Overwrite? [y/N] " response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
      echo "Aborted."
      exit 0
    fi
  fi
  echo "Removing existing prefix..."
  rm -rf "$WINEPREFIX"
fi

# ------------------------
# Create Prefix
# ------------------------
echo "Creating new Wine prefix..."
export WINEPREFIX WINEARCH
export WINEDLLOVERRIDES="mscoree,mshtml="  # Disable mono/gecko prompts

wineboot --init
echo "✅ Prefix initialized"

# ------------------------
# Install Core Components
# ------------------------
echo
echo "Installing core components..."
winetricks -q corefonts || echo "⚠️  corefonts failed (non-critical)"

# ------------------------
# Detect GPU & Write Config
# ------------------------
GPU="$(detect_gpu)"
VK_ICD="$(get_vk_icd "$GPU")"

echo
echo "Detected GPU: $GPU"
[[ -n "$VK_ICD" ]] && echo "Vulkan ICD: $VK_ICD"

# Create config file
mkdir -p "$WINEPREFIX"
cat > "$WINEPREFIX/prefix.conf" <<EOF
# Wine Prefix Configuration
PREFIX_NAME="${PREFIX_NAME:-$(basename "$WINEPREFIX")}"
WINEPREFIX="$WINEPREFIX"
WINEARCH="$WINEARCH"
GPU_TYPE="$GPU"
VK_ICD_FILENAMES="$VK_ICD"
CREATED="$(date -u +"%Y-%m-%d %H:%M:%S UTC")"
EOF

# ------------------------
# Create Basic Env File
# ------------------------
cat > "$WINEPREFIX/env.sh" <<EOF
#!/usr/bin/env bash
# Basic environment for this Wine prefix
export WINEPREFIX="$WINEPREFIX"
export WINEARCH="$WINEARCH"
export WINEDEBUG=-all

# GPU-specific
export SUPERWINE_GPU="$GPU"
[[ -n "$VK_ICD" ]] && export VK_ICD_FILENAMES="$VK_ICD"
EOF

chmod +x "$WINEPREFIX/env.sh"

# ------------------------
# Summary
# ------------------------
echo
echo "✅ Wine prefix created successfully!"
echo
echo "Prefix location: $WINEPREFIX"
echo "Configuration: $WINEPREFIX/prefix.conf"
echo "Environment: $WINEPREFIX/env.sh"
echo
echo "Next steps:"
echo "  1. Source environment: source $WINEPREFIX/env.sh"
echo "  2. Configure for specific use:"
echo "     - Gaming: ./03-configure-gaming.sh --prefix $WINEPREFIX"
echo "     - Photoshop: ./04-configure-photoshop.sh --prefix $WINEPREFIX"
