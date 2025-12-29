#!/usr/bin/env bash
# 04-configure-photoshop.sh
# Configure Wine prefix specifically for Adobe Photoshop CS6
set -euo pipefail

# ------------------------
# CLI args
# ------------------------
WINEPREFIX=""
INSTALL_DXVK=0
MEMORY_SIZE="2048"
HISTORY_STATES="20"

usage() {
  cat <<EOF
Usage: $0 --prefix PATH [OPTIONS]

Configure a Wine prefix for Adobe Photoshop CS6 with stability optimizations.

REQUIRED:
  --prefix PATH      Wine prefix to configure

OPTIONS:
  --with-dxvk       Enable DXVK (experimental, may cause crashes)
  --memory SIZE     Video memory size in MB (default: 2048)
  --history NUM     Photoshop history states (default: 20)
  -h, --help        Show this help

FEATURES:
  - Adobe-specific runtime libraries
  - Stability-focused registry tweaks
  - Optimized Direct3D settings
  - Memory management tuning
  - Crash prevention configurations

EXAMPLES:
  $0 --prefix ~/.wine-photoshop
  $0 --prefix ~/.wine-photoshop --memory 4096 --history 30
  $0 --prefix ~/.wine-photoshop --with-dxvk  # experimental
EOF
  exit 0
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --prefix) WINEPREFIX="$2"; shift 2 ;;
    --with-dxvk) INSTALL_DXVK=1; shift ;;
    --memory) MEMORY_SIZE="$2"; shift 2 ;;
    --history) HISTORY_STATES="$2"; shift 2 ;;
    -h|--help) usage ;;
    *) echo "Unknown argument: $1"; usage ;;
  esac
done

if [[ -z "$WINEPREFIX" ]]; then
  echo "❌ Error: --prefix is required"
  usage
fi

if [[ ! -d "$WINEPREFIX" ]]; then
  echo "❌ Error: Prefix does not exist: $WINEPREFIX"
  echo "Create it first with: ./02-create-wine-prefix.sh --prefix $WINEPREFIX"
  exit 1
fi

echo "🎨 Wine Photoshop CS6 Configuration"
echo "===================================="
echo "Prefix: $WINEPREFIX"
echo "Video Memory: ${MEMORY_SIZE}MB"
echo

export WINEPREFIX

# ------------------------
# Install Required Runtimes
# ------------------------
echo "Installing Adobe-compatible runtimes..."
echo

# Core fonts (essential for Photoshop UI)
echo "Installing fonts..."
winetricks -q corefonts || echo "⚠️  corefonts warning (non-critical)"

# Visual C++ runtimes (Photoshop CS6 needs these)
echo "Installing Visual C++ 2008-2013..."
winetricks -q vcrun2008 vcrun2010 vcrun2012 vcrun2013 || {
  echo "⚠️  Some VC++ runtimes failed, trying individually..."
  winetricks vcrun2008 2>/dev/null || true
  winetricks vcrun2010 2>/dev/null || true
}

# Microsoft XML parsers
echo "Installing XML libraries..."
winetricks -q msxml3 msxml6 || true

# GDI+ and other graphics libs
echo "Installing graphics libraries..."
winetricks -q gdiplus atmlib || true

# DirectX (minimal, for GPU acceleration)
echo "Installing DirectX components..."
winetricks -q d3dx9 d3dcompiler_43 d3dcompiler_47 || true

# ------------------------
# Optional: DXVK
# ------------------------
if [[ "$INSTALL_DXVK" -eq 1 ]]; then
  echo
  echo "Installing DXVK (experimental for Photoshop)..."
  echo "⚠️  Note: DXVK may cause instability in Photoshop"
  winetricks -q dxvk || echo "⚠️  DXVK installation failed"
fi

# ------------------------
# Registry Tweaks for Stability
# ------------------------
echo
echo "Applying Photoshop-optimized registry settings..."
cat > /tmp/photoshop-tweaks.reg <<REG
Windows Registry Editor Version 5.00

[HKEY_CURRENT_USER\Software\Wine\Direct3D]
"DirectDrawRenderer"="opengl"
"MaxVersionGL"=dword:00040006
"UseGLSL"="enabled"
"VideoMemorySize"="$MEMORY_SIZE"
"OffscreenRenderingMode"="fbo"
"StrictDrawOrdering"="disabled"
"Multisampling"="disabled"
"AlwaysOffscreen"="enabled"

[HKEY_CURRENT_USER\Software\Wine\DllOverrides]
"winemenubuilder.exe"=""

[HKEY_CURRENT_USER\Software\Wine\X11 Driver]
"UseTakeFocus"="N"
"Decorated"="Y"

[HKEY_CURRENT_USER\Control Panel\Desktop]
"FontSmoothing"="2"
"FontSmoothingType"=dword:00000002
"FontSmoothingGamma"=dword:00000578
REG

wine regedit /tmp/photoshop-tweaks.reg 2>/dev/null
rm -f /tmp/photoshop-tweaks.reg
echo "✅ Registry tweaks applied"

# ------------------------
# Create Photoshop Environment
# ------------------------
echo
echo "Creating Photoshop environment file..."

GPU_TYPE="unknown"
VK_ICD=""
if [[ -f "$WINEPREFIX/prefix.conf" ]]; then
  GPU_TYPE=$(grep "^GPU_TYPE=" "$WINEPREFIX/prefix.conf" | cut -d'"' -f2 || echo "unknown")
  VK_ICD=$(grep "^VK_ICD_FILENAMES=" "$WINEPREFIX/prefix.conf" | cut -d'"' -f2 || echo "")
fi

cat > "$WINEPREFIX/photoshop-env.sh" <<EOF
#!/usr/bin/env bash
# Photoshop CS6 optimized environment

# Load base environment
[[ -f "$WINEPREFIX/env.sh" ]] && source "$WINEPREFIX/env.sh"

# Disable debug output for performance
export WINEDEBUG=-all

# Stability settings
export STAGING_SHARED_MEMORY=1
export WINE_CPU_TOPOLOGY=4:0  # Limit to 4 cores for stability

# GPU acceleration settings
EOF

case "$GPU_TYPE" in
  nvidia)
    cat >> "$WINEPREFIX/photoshop-env.sh" <<'EOF'
export __GL_THREADED_OPTIMIZATION=1
export __GL_SHADER_DISK_CACHE=1
export __GL_SHADER_DISK_CACHE_PATH="$WINEPREFIX/gl_cache"
export __GL_YIELD="USLEEP"
EOF
    ;;
  amd)
    cat >> "$WINEPREFIX/photoshop-env.sh" <<'EOF'
export mesa_glthread=true
export AMD_DEBUG=nohyperz
export RADV_DEBUG=nohiz,nofmask
EOF
    ;;
  intel)
    cat >> "$WINEPREFIX/photoshop-env.sh" <<'EOF'
export mesa_glthread=true
export INTEL_DEBUG=nofc
EOF
    ;;
esac

if [[ "$INSTALL_DXVK" -eq 1 ]]; then
  cat >> "$WINEPREFIX/photoshop-env.sh" <<'EOF'

# DXVK settings (if enabled)
export DXVK_STATE_CACHE=1
export DXVK_STATE_CACHE_PATH="$WINEPREFIX/dxvk_cache"
export DXVK_LOG_LEVEL=none
export DXVK_HUD=0
EOF
fi

cat >> "$WINEPREFIX/photoshop-env.sh" <<'EOF'

# Memory optimization
export WINE_HEAP_DELAY_FREE=1

# Vulkan ICD
EOF
echo "export VK_ICD_FILENAMES=\"$VK_ICD\"" >> "$WINEPREFIX/photoshop-env.sh"

chmod +x "$WINEPREFIX/photoshop-env.sh"

# ------------------------
# Create Photoshop Launcher
# ------------------------
echo
echo "Creating Photoshop launcher..."
LAUNCHER="$WINEPREFIX/run-photoshop.sh"

cat > "$LAUNCHER" <<'EOF'
#!/usr/bin/env bash
# Adobe Photoshop CS6 launcher

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
source "$SCRIPT_DIR/photoshop-env.sh"

# Default Photoshop installation paths
PS_PATHS=(
  "$WINEPREFIX/drive_c/Program Files/Adobe/Adobe Photoshop CS6/Photoshop.exe"
  "$WINEPREFIX/drive_c/Program Files (x86)/Adobe/Adobe Photoshop CS6/Photoshop.exe"
  "$WINEPREFIX/drive_c/Program Files/Adobe/Adobe Photoshop CS6 (64 Bit)/Photoshop.exe"
)

# Find Photoshop executable
PS_EXE=""
if [[ -n "$1" ]] && [[ -f "$1" ]]; then
  PS_EXE="$1"
else
  for path in "${PS_PATHS[@]}"; do
    if [[ -f "$path" ]]; then
      PS_EXE="$path"
      break
    fi
  done
fi

if [[ -z "$PS_EXE" ]]; then
  echo "❌ Photoshop.exe not found!"
  echo
  echo "Please specify the path:"
  echo "  $0 /path/to/Photoshop.exe"
  echo
  echo "Or install Photoshop CS6 to one of these locations:"
  for path in "${PS_PATHS[@]}"; do
    echo "  $path"
  done
  exit 1
fi

echo "🎨 Launching Photoshop CS6..."
echo "Executable: $PS_EXE"
echo

exec wine "$PS_EXE" "$@"
EOF

chmod +x "$LAUNCHER"

# ------------------------
# Create Photoshop Settings Guide
# ------------------------
echo
echo "Creating Photoshop settings guide..."
cat > "$WINEPREFIX/PHOTOSHOP-SETTINGS.txt" <<EOF
RECOMMENDED PHOTOSHOP CS6 SETTINGS FOR WINE
==========================================

After launching Photoshop, configure these settings for best stability:

1. Edit → Preferences → Performance:
   ✓ Memory Usage: 60-70% (NOT 100%)
   ✓ History States: $HISTORY_STATES
   ✓ Cache Levels: 4
   ✓ Graphics Processor: DISABLE if crashes occur
      - Try enabling OpenGL drawing first
      - If crashes continue, disable completely

2. Edit → Preferences → File Handling:
   ✓ Disable "Save in Background"
   ✓ Maximize PSD/PSB File Compatibility: Ask or Always

3. Edit → Preferences → Interface:
   ✓ UI Scaling: 100% (avoid scaling issues)

4. Edit → Preferences → Cursors:
   ✓ Painting Cursors: Normal Brush Tip
   ✓ Other Cursors: Standard

TROUBLESHOOTING
===============

If Photoshop crashes:
  1. Disable GPU acceleration (see Performance settings above)
  2. Reduce Memory Usage to 50%
  3. Lower History States to 10
  4. Disable "Save in Background"

If UI appears broken:
  1. Check font installation: winetricks corefonts
  2. Reset workspace: Window → Workspace → Reset Essentials

If file operations are slow:
  1. Work on native Linux partition (ext4), not NTFS
  2. Disable antivirus if running in Wine

Performance tips:
  - Keep file sizes reasonable (<2GB)
  - Use Smart Objects sparingly
  - Purge clipboard/history regularly: Edit → Purge
  - Close unused documents

Known limitations:
  - Some plugins may not work
  - Camera Raw might be unstable (use DNG Converter)
  - 3D features are limited/unstable
  - Some filters may crash (test before production work)
EOF

# ------------------------
# System Check
# ------------------------
echo
echo "Checking system resources..."

TOTAL_RAM=$(free -g | awk '/^Mem:/{print $2}')
if [[ "$TOTAL_RAM" -lt 4 ]]; then
  echo "⚠️  Low RAM detected: ${TOTAL_RAM}GB"
  echo "   Photoshop CS6 needs at least 4GB, 8GB+ recommended"
fi

# Check GPU
if ! command -v vulkaninfo >/dev/null 2>&1; then
  echo "⚠️  vulkaninfo not found - install vulkan-tools to verify GPU"
fi

# ------------------------
# Summary
# ------------------------
echo
echo "✅ Photoshop CS6 configuration complete!"
echo
echo "Files created:"
echo "  $WINEPREFIX/photoshop-env.sh"
echo "  $WINEPREFIX/run-photoshop.sh"
echo "  $WINEPREFIX/PHOTOSHOP-SETTINGS.txt"
echo
echo "Next steps:"
echo "  1. Install Photoshop CS6:"
echo "     wine $WINEPREFIX/setup.exe"
echo
echo "  2. Launch Photoshop:"
echo "     $WINEPREFIX/run-photoshop.sh"
echo
echo "  3. Configure settings (see PHOTOSHOP-SETTINGS.txt)"
echo
echo "  4. READ SETTINGS GUIDE:"
echo "     cat $WINEPREFIX/PHOTOSHOP-SETTINGS.txt"
echo

if [[ "$INSTALL_DXVK" -eq 1 ]]; then
  echo "⚠️  DXVK is enabled (experimental)"
  echo "   If you experience crashes, reconfigure without --with-dxvk"
  echo
fi

echo "Troubleshooting:"
echo "  - If crashes: Disable GPU in Photoshop preferences"
echo "  - If slow: Check you're on native Linux filesystem (not NTFS)"
echo "  - If UI broken: Run 'winetricks corefonts' again"
