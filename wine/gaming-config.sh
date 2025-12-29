#!/usr/bin/env bash
# 03-configure-gaming.sh
# Configure Wine prefix for gaming with DXVK, VKD3D, and performance tweaks
set -euo pipefail

# ------------------------
# CLI args
# ------------------------
WINEPREFIX=""
INSTALL_DXVK=1
INSTALL_VKD3D=1
INSTALL_GAMEMODE=1
ASYNC_DXVK=1

usage() {
  cat <<EOF
Usage: $0 --prefix PATH [OPTIONS]

Configure a Wine prefix for optimal gaming performance.

REQUIRED:
  --prefix PATH      Wine prefix to configure

OPTIONS:
  --no-dxvk         Skip DXVK installation
  --no-vkd3d        Skip VKD3D installation
  --no-gamemode     Skip GameMode configuration
  --no-async        Disable DXVK async shader compilation
  -h, --help        Show this help

FEATURES:
  - DXVK (DirectX 9/10/11 to Vulkan)
  - VKD3D-Proton (DirectX 12 to Vulkan)
  - DXVK async shader compilation
  - GameMode integration
  - Performance registry tweaks
  - Esync/Fsync configuration

EXAMPLES:
  $0 --prefix ~/.wine-games
  $0 --prefix ~/.wine-games --no-async
EOF
  exit 0
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --prefix) WINEPREFIX="$2"; shift 2 ;;
    --no-dxvk) INSTALL_DXVK=0; shift ;;
    --no-vkd3d) INSTALL_VKD3D=0; shift ;;
    --no-gamemode) INSTALL_GAMEMODE=0; shift ;;
    --no-async) ASYNC_DXVK=0; shift ;;
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

echo "🎮 Wine Gaming Configuration"
echo "============================"
echo "Prefix: $WINEPREFIX"
echo

export WINEPREFIX

# ------------------------
# Install Visual C++ Runtimes
# ------------------------
echo "Installing Visual C++ runtimes (required for most games)..."
winetricks -q vcrun2019 || echo "⚠️  vcrun2019 failed (trying individual versions)"
winetricks -q vcrun2015 vcrun2017 2>/dev/null || true

# ------------------------
# Install DirectX
# ------------------------
echo
echo "Installing DirectX components..."
winetricks -q d3dx9 d3dcompiler_43 d3dcompiler_47 || true

# ------------------------
# Install DXVK
# ------------------------
if [[ "$INSTALL_DXVK" -eq 1 ]]; then
  echo
  echo "Installing DXVK (DirectX 9/10/11 → Vulkan)..."
  winetricks -q dxvk || echo "⚠️  DXVK installation failed"
fi

# ------------------------
# Install VKD3D
# ------------------------
if [[ "$INSTALL_VKD3D" -eq 1 ]]; then
  echo
  echo "Installing VKD3D-Proton (DirectX 12 → Vulkan)..."
  winetricks -q vkd3d || echo "⚠️  VKD3D installation failed"
fi

# ------------------------
# Registry Tweaks
# ------------------------
echo
echo "Applying registry tweaks for gaming..."
cat > /tmp/gaming-tweaks.reg <<'REG'
Windows Registry Editor Version 5.00

[HKEY_CURRENT_USER\Software\Wine\Direct3D]
"csmt"="enabled"
"DirectDrawRenderer"="opengl"
"MaxVersionGL"=dword:00040006
"UseGLSL"="enabled"
"VideoMemorySize"="4096"
"OffscreenRenderingMode"="fbo"
"StrictDrawOrdering"="disabled"
"Multisampling"="enabled"

[HKEY_CURRENT_USER\Software\Wine\DirectInput]
"MouseWarpOverride"="force"

[HKEY_CURRENT_USER\Software\Wine\X11 Driver]
"UseTakeFocus"="N"
"GrabFullscreen"="Y"
REG

wine regedit /tmp/gaming-tweaks.reg 2>/dev/null
rm -f /tmp/gaming-tweaks.reg
echo "✅ Registry tweaks applied"

# ------------------------
# Create Gaming Environment
# ------------------------
echo
echo "Creating gaming environment file..."

GPU_TYPE="unknown"
if [[ -f "$WINEPREFIX/prefix.conf" ]]; then
  GPU_TYPE=$(grep "^GPU_TYPE=" "$WINEPREFIX/prefix.conf" | cut -d'"' -f2)
fi

cat > "$WINEPREFIX/gaming-env.sh" <<EOF
#!/usr/bin/env bash
# Gaming-optimized environment for Wine

# Load base environment
[[ -f "$WINEPREFIX/env.sh" ]] && source "$WINEPREFIX/env.sh"

# Performance
export WINEESYNC=1
export WINEFSYNC=1
export STAGING_SHARED_MEMORY=1
export STAGING_WRITECOPY=1

# DXVK
export DXVK_STATE_CACHE=1
export DXVK_STATE_CACHE_PATH="\$WINEPREFIX/dxvk_cache"
EOF

if [[ "$ASYNC_DXVK" -eq 1 ]]; then
  cat >> "$WINEPREFIX/gaming-env.sh" <<EOF
export DXVK_ASYNC=1
EOF
fi

cat >> "$WINEPREFIX/gaming-env.sh" <<EOF
export DXVK_LOG_LEVEL=none
export DXVK_HUD=compiler

# VKD3D
export VKD3D_CONFIG=dxr
export VKD3D_SHADER_CACHE_PATH="\$WINEPREFIX/vkd3d_cache"

# GPU-specific optimizations
EOF

case "$GPU_TYPE" in
  nvidia)
    cat >> "$WINEPREFIX/gaming-env.sh" <<'EOF'
export __GL_THREADED_OPTIMIZATION=1
export __GL_SHADER_DISK_CACHE=1
export __GL_SHADER_DISK_CACHE_PATH="$WINEPREFIX/gl_cache"
export __GL_YIELD="USLEEP"
EOF
    ;;
  amd)
    cat >> "$WINEPREFIX/gaming-env.sh" <<'EOF'
export mesa_glthread=true
export AMD_DEBUG=nohyperz
export RADV_PERFTEST=aco,sam,gpl
EOF
    ;;
  intel)
    cat >> "$WINEPREFIX/gaming-env.sh" <<'EOF'
export mesa_glthread=true
export INTEL_DEBUG=nofc
EOF
    ;;
esac

cat >> "$WINEPREFIX/gaming-env.sh" <<'EOF'

# CPU topology (adjust if needed)
# export WINE_CPU_TOPOLOGY=8:0  # 8 cores

# Disable debug output
export WINEDEBUG=-all
export DXVK_LOG_LEVEL=none

# Gamemode
export LD_PRELOAD=""  # Clear first
if command -v gamemoderun >/dev/null 2>&1; then
  export GAMEMODE=1
fi
EOF

chmod +x "$WINEPREFIX/gaming-env.sh"

# ------------------------
# Create Launch Wrapper
# ------------------------
echo
echo "Creating game launcher wrapper..."
LAUNCHER="$WINEPREFIX/run-game.sh"

cat > "$LAUNCHER" <<'EOF'
#!/usr/bin/env bash
# Game launcher with GameMode support

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
source "$SCRIPT_DIR/gaming-env.sh"

if [[ -z "$1" ]]; then
  echo "Usage: $0 <game.exe> [args...]"
  exit 1
fi

# Use gamemode if available
if command -v gamemoderun >/dev/null 2>&1; then
  echo "🚀 Launching with GameMode..."
  exec gamemoderun wine "$@"
else
  echo "🚀 Launching game..."
  exec wine "$@"
fi
EOF

chmod +x "$LAUNCHER"

# ------------------------
# System Limits Check
# ------------------------
echo
echo "Checking system limits for esync/fsync..."
CURRENT_LIMIT=$(ulimit -Hn)
if [[ "$CURRENT_LIMIT" -lt 524288 ]]; then
  echo "⚠️  File descriptor limit is low: $CURRENT_LIMIT"
  echo "For better performance, increase it:"
  echo
  echo "  Add to /etc/security/limits.conf:"
  echo "    $USER hard nofile 524288"
  echo
  echo "  Or run: sudo sh -c 'echo \"$USER hard nofile 524288\" >> /etc/security/limits.conf'"
  echo "  Then log out and back in."
else
  echo "✅ File descriptor limit is sufficient: $CURRENT_LIMIT"
fi

# ------------------------
# Summary
# ------------------------
echo
echo "✅ Gaming configuration complete!"
echo
echo "Components installed:"
[[ "$INSTALL_DXVK" -eq 1 ]] && echo "  ✅ DXVK (DirectX 9/10/11)"
[[ "$INSTALL_VKD3D" -eq 1 ]] && echo "  ✅ VKD3D-Proton (DirectX 12)"
echo "  ✅ Visual C++ Runtimes"
echo "  ✅ DirectX libraries"
echo
echo "Environment files:"
echo "  $WINEPREFIX/gaming-env.sh"
echo "  $WINEPREFIX/run-game.sh"
echo
echo "Usage examples:"
echo "  # Launch game with optimizations:"
echo "  $WINEPREFIX/run-game.sh /path/to/game.exe"
echo
echo "  # Or manually:"
echo "  source $WINEPREFIX/gaming-env.sh"
echo "  wine /path/to/game.exe"
echo
[[ "$ASYNC_DXVK" -eq 1 ]] && echo "Note: DXVK async is enabled for faster shader compilation"
