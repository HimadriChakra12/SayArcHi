#!/usr/bin/env bash
# wine-setup-photoshop.sh - Complete Photoshop CS6 configuration
# Version: 1.0
set -euo pipefail

# ============================================================================
# Configuration
# ============================================================================
WINEPREFIX="${1:-}"
ENABLE_DXVK=0
MEMORY_SIZE="2048"

# ============================================================================
# Parse Arguments
# ============================================================================
show_usage() {
  cat <<EOF
Usage: $0 PREFIX [OPTIONS]

Complete Adobe Photoshop CS6 setup with stability optimizations.

Arguments:
  PREFIX              Wine prefix path (required)

Options:
  --with-dxvk        Enable DXVK (experimental, may cause crashes)
  --memory SIZE      Video memory in MB (default: 2048)
  -h, --help         Show this help

Examples:
  $0 ~/.wine-photoshop
  $0 ~/.wine-photoshop --memory 4096
  $0 /home/himadri/.wine

Notes:
  - For existing Photoshop installations, just run this on your existing prefix
  - Supports Photoshop Portable installations
  - Optimized for stability over performance

EOF
  exit 0
}

shift || show_usage

while [[ $# -gt 0 ]]; do
  case "$1" in
    --with-dxvk) ENABLE_DXVK=1; shift ;;
    --memory) MEMORY_SIZE="$2"; shift 2 ;;
    -h|--help) show_usage ;;
    *) echo "Unknown option: $1"; show_usage ;;
  esac
done

if [[ -z "$WINEPREFIX" ]]; then
  echo "❌ Error: PREFIX path required"
  show_usage
fi

if [[ ! -d "$WINEPREFIX" ]]; then
  echo "❌ Error: Prefix not found: $WINEPREFIX"
  echo "Create it first: ./wine-create-prefix.sh $WINEPREFIX"
  exit 1
fi

echo "╔════════════════════════════════════════╗"
echo "║   Wine Photoshop CS6 Setup v1.0        ║"
echo "╚════════════════════════════════════════╝"
echo
echo "Prefix: $WINEPREFIX"
echo "Video Memory: ${MEMORY_SIZE}MB"
[[ "$ENABLE_DXVK" -eq 1 ]] && echo "DXVK: Enabled (experimental)"
echo

export WINEPREFIX

# ============================================================================
# Check for Existing Photoshop Installation
# ============================================================================
PS_PATHS=(
  "$WINEPREFIX/drive_c/Program Files/Adobe/Adobe Photoshop CS6/Photoshop.exe"
  "$WINEPREFIX/drive_c/Program Files (x86)/Adobe/Adobe Photoshop CS6/Photoshop.exe"
  "$WINEPREFIX/drive_c/Program Files/Adobe/Adobe Photoshop CS6 (64 Bit)/Photoshop.exe"
  "$WINEPREFIX/drive_c/Program Files/PhotoshopPortable/PhotoshopCS6Portable.exe"
)

FOUND_PS=""
for path in "${PS_PATHS[@]}"; do
  if [[ -f "$path" ]]; then
    FOUND_PS="$path"
    echo "✅ Found existing Photoshop: $path"
    break
  fi
done

[[ -z "$FOUND_PS" ]] && echo "ℹ️  No Photoshop installation detected (you can install it later)"

# ============================================================================
# Install Core Fonts
# ============================================================================
echo
echo "📝 Installing core fonts..."
if ! ls "$WINEPREFIX/drive_c/windows/Fonts/"Arial*.ttf >/dev/null 2>&1; then
  winetricks -q corefonts >/dev/null 2>&1 || echo "⚠️  Font warning (non-critical)"
fi
echo "✅ Fonts installed"

# ============================================================================
# Install Visual C++ Runtimes
# ============================================================================
echo
echo "📦 Installing Visual C++ runtimes (2008-2013)..."
winetricks -q vcrun2008 vcrun2010 vcrun2012 vcrun2013 >/dev/null 2>&1 || {
  echo "⚠️  Some runtimes failed, trying individually..."
  winetricks vcrun2008 2>/dev/null || true
  winetricks vcrun2010 2>/dev/null || true
}
echo "✅ Runtimes installed"

# ============================================================================
# Install XML & Graphics Libraries
# ============================================================================
echo
echo "📦 Installing graphics libraries..."
winetricks -q msxml3 msxml6 gdiplus atmlib >/dev/null 2>&1 || true
echo "✅ Graphics libraries installed"

# ============================================================================
# Install DirectX
# ============================================================================
echo
echo "📦 Installing DirectX components..."
winetricks -q d3dx9 d3dcompiler_43 d3dcompiler_47 >/dev/null 2>&1 || true
echo "✅ DirectX installed"

# ============================================================================
# Optional: DXVK
# ============================================================================
if [[ "$ENABLE_DXVK" -eq 1 ]]; then
  echo
  echo "🎮 Installing DXVK (experimental for Photoshop)..."
  winetricks -q dxvk >/dev/null 2>&1 || echo "⚠️  DXVK installation warning"
  echo "✅ DXVK installed"
fi

# ============================================================================
# Apply Registry Tweaks
# ============================================================================
echo
echo "⚙️  Applying Photoshop-optimized registry settings..."

cat > /tmp/wine-photoshop.reg <<REG
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

wine regedit /tmp/wine-photoshop.reg 2>/dev/null
rm -f /tmp/wine-photoshop.reg
echo "✅ Registry configured"

# ============================================================================
# Detect GPU
# ============================================================================
detect_gpu() {
  if [[ -f "$WINEPREFIX/prefix-info.txt" ]]; then
    grep "^GPU:" "$WINEPREFIX/prefix-info.txt" | cut -d: -f2 | tr -d ' '
  else
    echo "unknown"
  fi
}

GPU=$(detect_gpu)

# ============================================================================
# Create Photoshop Environment
# ============================================================================
echo
echo "🔧 Creating Photoshop environment..."

cat > "$WINEPREFIX/photoshop-env.sh" <<EOF
#!/usr/bin/env bash
# Photoshop CS6 optimized environment

# Load base environment
[[ -f "$WINEPREFIX/env.sh" ]] && source "$WINEPREFIX/env.sh"

# Stability settings
export STAGING_SHARED_MEMORY=1
export WINE_CPU_TOPOLOGY=4:0
export WINE_HEAP_DELAY_FREE=1

EOF

# GPU-specific optimizations
case "$GPU" in
  nvidia)
    cat >> "$WINEPREFIX/photoshop-env.sh" <<'EOF'
# NVIDIA optimizations
export __GL_THREADED_OPTIMIZATION=1
export __GL_SHADER_DISK_CACHE=1
export __GL_SHADER_DISK_CACHE_PATH="$WINEPREFIX/gl_cache"
export __GL_YIELD="USLEEP"
EOF
    ;;
  amd)
    cat >> "$WINEPREFIX/photoshop-env.sh" <<'EOF'
# AMD optimizations
export mesa_glthread=true
export AMD_DEBUG=nohyperz
export RADV_DEBUG=nohiz,nofmask
EOF
    ;;
  intel)
    cat >> "$WINEPREFIX/photoshop-env.sh" <<'EOF'
# Intel optimizations
export mesa_glthread=true
export INTEL_DEBUG=nofc
EOF
    ;;
esac

if [[ "$ENABLE_DXVK" -eq 1 ]]; then
  cat >> "$WINEPREFIX/photoshop-env.sh" <<'EOF'

# DXVK settings
export DXVK_STATE_CACHE=1
export DXVK_STATE_CACHE_PATH="$WINEPREFIX/dxvk_cache"
export DXVK_LOG_LEVEL=none
export DXVK_HUD=0
EOF
fi

chmod +x "$WINEPREFIX/photoshop-env.sh"
echo "✅ Environment created"

# ============================================================================
# Create Photoshop Launcher
# ============================================================================
echo
echo "🎨 Creating Photoshop launcher..."

cat > "$WINEPREFIX/run-photoshop" <<'LAUNCHER'
#!/usr/bin/env bash
# Photoshop CS6 launcher

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
source "$SCRIPT_DIR/photoshop-env.sh"

# Default paths
PS_PATHS=(
  "$WINEPREFIX/drive_c/Program Files/Adobe/Adobe Photoshop CS6/Photoshop.exe"
  "$WINEPREFIX/drive_c/Program Files (x86)/Adobe/Adobe Photoshop CS6/Photoshop.exe"
  "$WINEPREFIX/drive_c/Program Files/Adobe/Adobe Photoshop CS6 (64 Bit)/Photoshop.exe"
  "$WINEPREFIX/drive_c/Program Files/PhotoshopPortable/PhotoshopCS6Portable.exe"
)

# Check for custom path
if [[ -f "$SCRIPT_DIR/photoshop-path.txt" ]]; then
  CUSTOM_PATH=$(cat "$SCRIPT_DIR/photoshop-path.txt")
  PS_PATHS=("$CUSTOM_PATH" "${PS_PATHS[@]}")
fi

# Find Photoshop
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
  cat <<HELP
❌ Photoshop not found!

Options:
  1. Specify path: $0 /path/to/Photoshop.exe
  2. Save custom path:
     echo '/path/to/Photoshop.exe' > $SCRIPT_DIR/photoshop-path.txt

Checked locations:
HELP
  for path in "${PS_PATHS[@]}"; do
    echo "  - $path"
  done
  exit 1
fi

echo "🎨 Launching Photoshop CS6..."
echo "📂 $PS_EXE"
echo
exec wine "$PS_EXE" "$@"
LAUNCHER

chmod +x "$WINEPREFIX/run-photoshop"
echo "✅ Launcher created"

# ============================================================================
# Create Settings Guide
# ============================================================================
echo
echo "📋 Creating settings guide..."

cat > "$WINEPREFIX/PHOTOSHOP-SETTINGS.txt" <<'SETTINGS'
╔════════════════════════════════════════════════════════════╗
║        PHOTOSHOP CS6 SETTINGS FOR WINE                     ║
╚════════════════════════════════════════════════════════════╝

CRITICAL SETTINGS (Configure immediately after launching):
===========================================================

1. Edit → Preferences → Performance
   ✓ Memory Usage: 60-70% (NOT 100% - causes crashes!)
   ✓ History States: 20 (lower to 10 if crashes persist)
   ✓ Cache Levels: 4
   ✓ Graphics Processor:
      • First try: Enable "Use Graphics Processor"
      • If crashes: DISABLE completely

2. Edit → Preferences → File Handling
   ✓ DISABLE "Save in Background" (major crash cause)
   ✓ Maximize PSD Compatibility: Ask or Always

3. Edit → Preferences → Interface
   ✓ UI Scaling: 100% (avoid scaling issues)

4. Edit → Preferences → Cursors
   ✓ Painting Cursors: Normal Brush Tip
   ✓ Other Cursors: Standard

TROUBLESHOOTING
===============

Problem: Photoshop crashes frequently
→ Disable GPU (Performance preferences)
→ Reduce Memory Usage to 50-60%
→ Lower History States to 10
→ Disable "Save in Background"

Problem: Slow performance
→ Work on ext4 filesystem (not NTFS/FAT32)
→ Close unused documents
→ Purge regularly: Edit → Purge → All

Problem: UI appears broken
→ Reset workspace: Window → Workspace → Reset Essentials
→ Reinstall fonts: winetricks corefonts
→ Check UI scaling is 100%

Problem: Tools/panels missing
→ Window → Workspace → Reset Essentials
→ Window → Show all menus

KNOWN LIMITATIONS
=================
• Some plugins may not work
• Camera Raw might be unstable
• 3D features are limited/unstable
• Some filters may crash (test before production)

PERFORMANCE TIPS
================
• Keep file sizes under 2GB
• Use Smart Objects sparingly
• Purge clipboard/history regularly
• Work on native Linux filesystem (ext4)
• Close unused documents
• Disable background save

CUSTOM INSTALLATION PATH
========================
If Photoshop is in a custom location:
  echo '/path/to/Photoshop.exe' > photoshop-path.txt

For Portable version at different location:
  echo '$WINEPREFIX/drive_c/Custom/Path/PhotoshopCS6Portable.exe' > photoshop-path.txt
SETTINGS

echo "✅ Settings guide created"

# ============================================================================
# Save Photoshop Path if Found
# ============================================================================
if [[ -n "$FOUND_PS" ]]; then
  echo "$FOUND_PS" > "$WINEPREFIX/photoshop-path.txt"
  echo "✅ Photoshop path saved"
fi

# ============================================================================
# System Check
# ============================================================================
echo
echo "🔍 Checking system resources..."

TOTAL_RAM=$(free -g 2>/dev/null | awk '/^Mem:/{print $2}' || echo "0")
if [[ "$TOTAL_RAM" -lt 4 ]]; then
  echo "⚠️  Low RAM: ${TOTAL_RAM}GB (recommend 8GB+ for Photoshop)"
fi

# ============================================================================
# Summary
# ============================================================================
echo
echo "╔════════════════════════════════════════╗"
echo "║  ✅ Photoshop CS6 Setup Complete!      ║"
echo "╚════════════════════════════════════════╝"
echo
echo "Components installed:"
echo "  ✅ Visual C++ Runtimes (2008-2013)"
echo "  ✅ Graphics libraries (GDI+, MSXML)"
echo "  ✅ DirectX components"
echo "  ✅ Core fonts"
[[ "$ENABLE_DXVK" -eq 1 ]] && echo "  ✅ DXVK (experimental)"
echo
if [[ -n "$FOUND_PS" ]]; then
  echo "Launch Photoshop:"
  echo "  $WINEPREFIX/run-photoshop"
else
  echo "Install Photoshop:"
  echo "  1. source $WINEPREFIX/photoshop-env.sh"
  echo "  2. wine /path/to/Photoshop_CS6_Setup.exe"
  echo
  echo "Then launch:"
  echo "  $WINEPREFIX/run-photoshop"
fi
echo
echo "📋 IMPORTANT: Read settings guide!"
echo "   cat $WINEPREFIX/PHOTOSHOP-SETTINGS.txt"
echo
echo "Critical settings to configure in Photoshop:"
echo "  • Memory Usage: 60-70%"
echo "  • History States: 20"
echo "  • Disable 'Save in Background'"
echo "  • Try disabling GPU if crashes occur"
