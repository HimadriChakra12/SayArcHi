#!/usr/bin/env bash
# configure-existing-photoshop.sh
# Configure an existing Wine prefix that already has Photoshop installed
set -euo pipefail

EXISTING_PREFIX="$HOME/.wine"
PS_EXE_PATH="$EXISTING_PREFIX/drive_c/Program Files/PhotoshopPortable/PhotoshopCS6Portable.exe"

echo "🎨 Configure Existing Photoshop Installation"
echo "============================================="
echo

# Check if prefix exists
if [[ ! -d "$EXISTING_PREFIX" ]]; then
  echo "❌ Wine prefix not found: $EXISTING_PREFIX"
  exit 1
fi

# Check if Photoshop exists
if [[ ! -f "$PS_EXE_PATH" ]]; then
  echo "⚠️  Photoshop not found at: $PS_EXE_PATH"
  read -rp "Enter path to your PhotoshopCS6Portable.exe: " PS_EXE_PATH
  
  if [[ ! -f "$PS_EXE_PATH" ]]; then
    echo "❌ File not found: $PS_EXE_PATH"
    exit 1
  fi
fi

echo "Found Photoshop at: $PS_EXE_PATH"
echo "Wine prefix: $EXISTING_PREFIX"
echo

export WINEPREFIX="$EXISTING_PREFIX"

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

GPU_TYPE=$(detect_gpu)
echo "Detected GPU: $GPU_TYPE"
echo

# ------------------------
# Install Missing Components
# ------------------------
echo "Checking and installing required components..."

# Core fonts
if ! ls "$WINEPREFIX/drive_c/windows/Fonts/"Arial*.ttf >/dev/null 2>&1; then
  echo "Installing core fonts..."
  winetricks -q corefonts || echo "⚠️ corefonts warning (non-critical)"
fi

# Check VC++ runtimes
echo "Checking Visual C++ runtimes..."
winetricks -q vcrun2010 vcrun2012 vcrun2013 2>/dev/null || true

# ------------------------
# Apply Registry Tweaks
# ------------------------
echo
echo "Applying Photoshop-optimized registry settings..."
cat > /tmp/photoshop-tweaks.reg <<'REG'
Windows Registry Editor Version 5.00

[HKEY_CURRENT_USER\Software\Wine\Direct3D]
"DirectDrawRenderer"="opengl"
"MaxVersionGL"=dword:00040006
"UseGLSL"="enabled"
"VideoMemorySize"="2048"
"OffscreenRenderingMode"="fbo"
"StrictDrawOrdering"="disabled"
"Multisampling"="disabled"
"AlwaysOffscreen"="enabled"

[HKEY_CURRENT_USER\Software\Wine\DllOverrides]
"winemenubuilder.exe"=""

[HKEY_CURRENT_USER\Software\Wine\X11 Driver]
"UseTakeFocus"="N"
"Decorated"="Y"
REG

wine regedit /tmp/photoshop-tweaks.reg 2>/dev/null
rm -f /tmp/photoshop-tweaks.reg
echo "✅ Registry tweaks applied"

# ------------------------
# Create Environment File
# ------------------------
echo
echo "Creating optimized environment file..."

cat > "$EXISTING_PREFIX/photoshop-env.sh" <<'EOF'
#!/usr/bin/env bash
# Photoshop CS6 optimized environment for existing Wine prefix

export WINEPREFIX="$HOME/.wine"
export WINEARCH=win64
export WINEDEBUG=-all

# Stability settings
export STAGING_SHARED_MEMORY=1
export WINE_CPU_TOPOLOGY=4:0

EOF

case "$GPU_TYPE" in
  nvidia)
    cat >> "$EXISTING_PREFIX/photoshop-env.sh" <<'EOF'
# NVIDIA optimizations
export __GL_THREADED_OPTIMIZATION=1
export __GL_SHADER_DISK_CACHE=1
export __GL_SHADER_DISK_CACHE_PATH="$WINEPREFIX/gl_cache"
export __GL_YIELD="USLEEP"
EOF
    ;;
  amd)
    cat >> "$EXISTING_PREFIX/photoshop-env.sh" <<'EOF'
# AMD optimizations
export mesa_glthread=true
export AMD_DEBUG=nohyperz
export RADV_DEBUG=nohiz,nofmask
EOF
    ;;
  intel)
    cat >> "$EXISTING_PREFIX/photoshop-env.sh" <<'EOF'
# Intel optimizations
export mesa_glthread=true
export INTEL_DEBUG=nofc
EOF
    ;;
esac

cat >> "$EXISTING_PREFIX/photoshop-env.sh" <<'EOF'

# Memory optimization
export WINE_HEAP_DELAY_FREE=1
EOF

chmod +x "$EXISTING_PREFIX/photoshop-env.sh"

# ------------------------
# Create Launcher
# ------------------------
echo
echo "Creating Photoshop launcher..."

cat > "$EXISTING_PREFIX/run-photoshop.sh" <<EOF
#!/usr/bin/env bash
# Photoshop CS6 launcher

SCRIPT_DIR="\$(dirname "\$(readlink -f "\$0")")"
source "\$SCRIPT_DIR/photoshop-env.sh"

PS_EXE="$PS_EXE_PATH"

if [[ ! -f "\$PS_EXE" ]]; then
  echo "❌ Photoshop not found at: \$PS_EXE"
  exit 1
fi

echo "🎨 Launching Photoshop CS6..."
echo "Executable: \$PS_EXE"
echo

exec wine "\$PS_EXE" "\$@"
EOF

chmod +x "$EXISTING_PREFIX/run-photoshop.sh"

# Save path to config
echo "$PS_EXE_PATH" > "$EXISTING_PREFIX/photoshop-path.conf"

# ------------------------
# Create Settings Guide
# ------------------------
cat > "$EXISTING_PREFIX/PHOTOSHOP-SETTINGS.txt" <<'EOF'
PHOTOSHOP CS6 SETTINGS FOR WINE
================================

Configure these settings in Photoshop for best stability:

1. Edit → Preferences → Performance:
   ✓ Memory Usage: 60-70% (NOT 100%)
   ✓ History States: 20
   ✓ Cache Levels: 4
   ✓ Graphics Processor: Try these in order:
      a) Enable "OpenGL Drawing"
      b) If crashes: Disable "Use Graphics Processor" entirely

2. Edit → Preferences → File Handling:
   ✓ Disable "Save in Background"
   ✓ Maximize PSD Compatibility: Ask or Always

3. Edit → Preferences → Interface:
   ✓ UI Scaling: 100%

TROUBLESHOOTING
===============

Crashes:
  1. Disable GPU (Performance preferences)
  2. Reduce Memory to 50%
  3. Lower History States to 10

Slow:
  - Work on ext4 filesystem (not NTFS)
  - Close unused documents
  - Purge: Edit → Purge → All

UI broken:
  - Reset workspace: Window → Workspace → Reset
  - Check fonts: winetricks corefonts

Known issues:
  - Some filters may crash
  - 3D features unstable
  - Camera Raw may be problematic
EOF

# ------------------------
# Summary
# ------------------------
echo
echo "✅ Configuration complete!"
echo
echo "Files created:"
echo "  $EXISTING_PREFIX/photoshop-env.sh"
echo "  $EXISTING_PREFIX/run-photoshop.sh"
echo "  $EXISTING_PREFIX/photoshop-path.conf"
echo "  $EXISTING_PREFIX/PHOTOSHOP-SETTINGS.txt"
echo
echo "Launch Photoshop:"
echo "  $EXISTING_PREFIX/run-photoshop.sh"
echo
echo "Or with environment:"
echo "  source $EXISTING_PREFIX/photoshop-env.sh"
echo "  wine '$PS_EXE_PATH'"
echo
echo "📋 IMPORTANT: Configure Photoshop settings!"
echo "   Read: cat $EXISTING_PREFIX/PHOTOSHOP-SETTINGS.txt"
echo
echo "   Key settings to change in Photoshop:"
echo "   1. Memory Usage: 60-70%"
echo "   2. History States: 20"
echo "   3. Disable GPU if crashes occur"
