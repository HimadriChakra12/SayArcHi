#!/usr/bin/env bash
# wine-setup-gaming.sh - Complete gaming configuration with DXVK, VKD3D, and resolution management
# Version: 1.0
set -euo pipefail

# ============================================================================
# Configuration
# ============================================================================
WINEPREFIX="${1:-}"
RESOLUTION=""
VIRTUAL_DESKTOP=""
SKIP_DXVK=0
SKIP_ASYNC=0

# ============================================================================
# Parse Arguments
# ============================================================================
show_usage() {
  cat <<EOF
Usage: $0 PREFIX [OPTIONS]

Complete gaming setup with DXVK, VKD3D, and performance optimizations.

Arguments:
  PREFIX                 Wine prefix path (required)

Options:
  --resolution WxH       Set default resolution (e.g., 1920x1080)
  --virtual WxH          Enable virtual desktop mode
  --no-dxvk             Skip DXVK installation (not recommended)
  --no-async            Disable DXVK async shaders
  -h, --help            Show this help

Examples:
  $0 ~/.wine-games
  $0 ~/.wine-games --resolution 1920x1080
  $0 ~/.wine-games --virtual 2560x1440
  $0 ~/.wine-fps --resolution 1280x720 --no-async

EOF
  exit 0
}

shift || show_usage

while [[ $# -gt 0 ]]; do
  case "$1" in
    --resolution) RESOLUTION="$2"; shift 2 ;;
    --virtual|--virtual-desktop) VIRTUAL_DESKTOP="$2"; shift 2 ;;
    --no-dxvk) SKIP_DXVK=1; shift ;;
    --no-async) SKIP_ASYNC=1; shift ;;
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
echo "║   Wine Gaming Setup v1.0               ║"
echo "╚════════════════════════════════════════╝"
echo
echo "Prefix: $WINEPREFIX"
[[ -n "$RESOLUTION" ]] && echo "Resolution: $RESOLUTION"
[[ -n "$VIRTUAL_DESKTOP" ]] && echo "Virtual Desktop: $VIRTUAL_DESKTOP"
echo

export WINEPREFIX

# ============================================================================
# Install Visual C++ Runtimes
# ============================================================================
echo "📦 Installing Visual C++ runtimes..."
winetricks -q vcrun2019 >/dev/null 2>&1 || {
  echo "⚠️  vcrun2019 failed, trying individual versions..."
  winetricks vcrun2015 vcrun2017 2>/dev/null || true
}
echo "✅ Runtimes installed"

# ============================================================================
# Install DirectX
# ============================================================================
echo
echo "📦 Installing DirectX components..."
winetricks -q d3dx9 d3dcompiler_43 d3dcompiler_47 >/dev/null 2>&1 || true
echo "✅ DirectX installed"

# ============================================================================
# Install DXVK & VKD3D
# ============================================================================
if [[ "$SKIP_DXVK" -eq 0 ]]; then
  echo
  echo "🎮 Installing DXVK (DirectX 9/10/11 → Vulkan)..."
  winetricks -q dxvk >/dev/null 2>&1 || echo "⚠️  DXVK installation warning"
  echo "✅ DXVK installed"
  
  echo
  echo "🎮 Installing VKD3D-Proton (DirectX 12 → Vulkan)..."
  winetricks -q vkd3d >/dev/null 2>&1 || echo "⚠️  VKD3D installation warning"
  echo "✅ VKD3D installed"
fi

# ============================================================================
# Apply Registry Tweaks
# ============================================================================
echo
echo "⚙️  Applying performance registry tweaks..."

# Validate resolution format
if [[ -n "$RESOLUTION" ]] && [[ ! "$RESOLUTION" =~ ^[0-9]+x[0-9]+$ ]]; then
  echo "⚠️  Invalid resolution format: $RESOLUTION (expected WIDTHxHEIGHT)"
  RESOLUTION=""
fi

if [[ -n "$VIRTUAL_DESKTOP" ]] && [[ ! "$VIRTUAL_DESKTOP" =~ ^[0-9]+x[0-9]+$ ]]; then
  echo "⚠️  Invalid virtual desktop format: $VIRTUAL_DESKTOP"
  VIRTUAL_DESKTOP=""
fi

# Base registry settings
cat > /tmp/wine-gaming.reg <<'REG'
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
"ScreenDepth"="32"
REG

# Add virtual desktop settings
if [[ -n "$VIRTUAL_DESKTOP" ]]; then
  cat >> /tmp/wine-gaming.reg <<REG

[HKEY_CURRENT_USER\Software\Wine\Explorer]
"Desktop"="shell"

[HKEY_CURRENT_USER\Software\Wine\Explorer\Desktops]
"shell"="$VIRTUAL_DESKTOP"
REG
elif [[ -n "$RESOLUTION" ]]; then
  cat >> /tmp/wine-gaming.reg <<REG

[HKEY_CURRENT_USER\Software\Wine\Explorer]
"Desktop"="Default"

[HKEY_CURRENT_USER\Software\Wine\Explorer\Desktops]
"Default"="$RESOLUTION"
REG
fi

wine regedit /tmp/wine-gaming.reg 2>/dev/null
rm -f /tmp/wine-gaming.reg
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
# Create Gaming Environment
# ============================================================================
echo
echo "🔧 Creating gaming environment..."

cat > "$WINEPREFIX/gaming-env.sh" <<EOF
#!/usr/bin/env bash
# Gaming-optimized environment

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
export DXVK_LOG_LEVEL=none
EOF

if [[ "$SKIP_ASYNC" -eq 0 ]]; then
  echo 'export DXVK_ASYNC=1' >> "$WINEPREFIX/gaming-env.sh"
fi

cat >> "$WINEPREFIX/gaming-env.sh" <<'EOF'

# VKD3D
export VKD3D_CONFIG=dxr
export VKD3D_SHADER_CACHE_PATH="$WINEPREFIX/vkd3d_cache"

EOF

# GPU-specific optimizations
case "$GPU" in
  nvidia)
    cat >> "$WINEPREFIX/gaming-env.sh" <<'EOF'
# NVIDIA optimizations
export __GL_THREADED_OPTIMIZATION=1
export __GL_SHADER_DISK_CACHE=1
export __GL_SHADER_DISK_CACHE_PATH="$WINEPREFIX/gl_cache"
export __GL_YIELD="USLEEP"
EOF
    ;;
  amd)
    cat >> "$WINEPREFIX/gaming-env.sh" <<'EOF'
# AMD optimizations
export mesa_glthread=true
export AMD_DEBUG=nohyperz
export RADV_PERFTEST=aco,sam,gpl
EOF
    ;;
  intel)
    cat >> "$WINEPREFIX/gaming-env.sh" <<'EOF'
# Intel optimizations
export mesa_glthread=true
export INTEL_DEBUG=nofc
EOF
    ;;
esac

chmod +x "$WINEPREFIX/gaming-env.sh"
echo "✅ Environment created"

# ============================================================================
# Create Game Launcher
# ============================================================================
echo
echo "🚀 Creating game launcher..."

cat > "$WINEPREFIX/run-game" <<'LAUNCHER'
#!/usr/bin/env bash
# Game launcher with resolution control

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
source "$SCRIPT_DIR/gaming-env.sh"

# Parse options
RESOLUTION=""
VIRTUAL_DESKTOP=""
FULLSCREEN=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    -r|--resolution)
      RESOLUTION="$2"
      shift 2
      ;;
    -v|--virtual|--virtual-desktop)
      VIRTUAL_DESKTOP="$2"
      shift 2
      ;;
    -f|--fullscreen)
      FULLSCREEN=1
      shift
      ;;
    -h|--help)
      cat <<HELP
Usage: $0 [OPTIONS] <game.exe> [game args...]

OPTIONS:
  -r, --resolution WxH   Set resolution (e.g., 1920x1080)
  -v, --virtual WxH      Virtual desktop mode
  -f, --fullscreen       Force fullscreen
  -h, --help             Show help

EXAMPLES:
  $0 game.exe
  $0 -r 1920x1080 game.exe
  $0 -v 2560x1440 game.exe
HELP
      exit 0
      ;;
    *)
      break
      ;;
  esac
done

if [[ -z "$1" ]]; then
  echo "Usage: $0 [OPTIONS] <game.exe>"
  echo "Run with -h for help"
  exit 1
fi

# Apply resolution
if [[ -n "$VIRTUAL_DESKTOP" ]]; then
  export WINE_EXPLORER_DESKTOP=shell
  export WINE_EXPLORER_DESKTOP_SIZE="$VIRTUAL_DESKTOP"
  echo "🖥️  Virtual desktop: $VIRTUAL_DESKTOP"
elif [[ -n "$RESOLUTION" ]]; then
  export WINE_GAME_RESOLUTION="$RESOLUTION"
  echo "🎮 Resolution: $RESOLUTION"
fi

if [[ "$FULLSCREEN" -eq 1 ]]; then
  unset WINE_EXPLORER_DESKTOP
  unset WINE_EXPLORER_DESKTOP_SIZE
  echo "🖼️  Fullscreen mode"
fi

# Launch with GameMode if available
if command -v gamemoderun >/dev/null 2>&1; then
  echo "🚀 Launching with GameMode..."
  exec gamemoderun wine "$@"
else
  echo "🚀 Launching game..."
  exec wine "$@"
fi
LAUNCHER

chmod +x "$WINEPREFIX/run-game"
echo "✅ Launcher created"

# ============================================================================
# Create Resolution Manager
# ============================================================================
echo
echo "🖥️  Creating resolution manager..."

cat > "$WINEPREFIX/set-resolution" <<'RESMGR'
#!/usr/bin/env bash
# Resolution manager

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
source "$SCRIPT_DIR/gaming-env.sh"

case "${1:-}" in
  --help|-h|"")
    cat <<HELP
Resolution Manager

Usage: $0 <COMMAND> [RESOLUTION]

Commands:
  set WxH        Set resolution (e.g., 1920x1080)
  virtual WxH    Enable virtual desktop
  fullscreen     Disable virtual desktop
  auto           Auto-detect native resolution
  current        Show current settings

Examples:
  $0 set 1920x1080
  $0 virtual 2560x1440
  $0 auto
HELP
    exit 0
    ;;
  set)
    RES="$2"
    cat > /tmp/res.reg <<REG
Windows Registry Editor Version 5.00

[HKEY_CURRENT_USER\Software\Wine\Explorer]
"Desktop"="Default"

[HKEY_CURRENT_USER\Software\Wine\Explorer\Desktops]
"Default"="$RES"
REG
    wine regedit /tmp/res.reg 2>/dev/null
    rm /tmp/res.reg
    echo "✅ Resolution set to $RES"
    ;;
  virtual)
    RES="$2"
    cat > /tmp/res.reg <<REG
Windows Registry Editor Version 5.00

[HKEY_CURRENT_USER\Software\Wine\Explorer]
"Desktop"="shell"

[HKEY_CURRENT_USER\Software\Wine\Explorer\Desktops]
"shell"="$RES"
REG
    wine regedit /tmp/res.reg 2>/dev/null
    rm /tmp/res.reg
    echo "✅ Virtual desktop enabled at $RES"
    ;;
  fullscreen)
    cat > /tmp/res.reg <<'REG'
Windows Registry Editor Version 5.00

[HKEY_CURRENT_USER\Software\Wine\Explorer]
"Desktop"=-
REG
    wine regedit /tmp/res.reg 2>/dev/null
    rm /tmp/res.reg
    echo "✅ Virtual desktop disabled (fullscreen mode)"
    ;;
  auto)
    if command -v xrandr >/dev/null 2>&1; then
      RES=$(xrandr | grep '\*' | awk '{print $1}' | head -n1)
      $0 set "$RES"
    else
      echo "❌ Cannot detect resolution (xrandr not found)"
      exit 1
    fi
    ;;
  current)
    echo "Current settings for: $WINEPREFIX"
    wine reg query "HKCU\\Software\\Wine\\Explorer" /v Desktop 2>/dev/null || echo "Mode: Fullscreen"
    ;;
  *)
    echo "Unknown command: $1"
    $0 --help
    ;;
esac
RESMGR

chmod +x "$WINEPREFIX/set-resolution"
echo "✅ Resolution manager created"

# ============================================================================
# Check System Limits
# ============================================================================
echo
echo "🔍 Checking system configuration..."

CURRENT_LIMIT=$(ulimit -Hn)
if [[ "$CURRENT_LIMIT" -lt 524288 ]]; then
  echo "⚠️  File descriptor limit is low: $CURRENT_LIMIT"
  echo "    For better performance, increase it:"
  echo "    sudo sh -c 'echo \"$USER hard nofile 524288\" >> /etc/security/limits.conf'"
  echo "    Then log out and back in."
else
  echo "✅ File descriptor limit OK: $CURRENT_LIMIT"
fi

# ============================================================================
# Summary
# ============================================================================
echo
echo "╔════════════════════════════════════════╗"
echo "║  ✅ Gaming Setup Complete!             ║"
echo "╚════════════════════════════════════════╝"
echo
echo "Installed components:"
[[ "$SKIP_DXVK" -eq 0 ]] && echo "  ✅ DXVK (DirectX 9/10/11)"
[[ "$SKIP_DXVK" -eq 0 ]] && echo "  ✅ VKD3D-Proton (DirectX 12)"
echo "  ✅ Visual C++ Runtimes"
echo "  ✅ DirectX libraries"
[[ "$SKIP_ASYNC" -eq 0 ]] && echo "  ✅ DXVK async enabled"
[[ -n "$RESOLUTION" ]] && echo "  ✅ Resolution: $RESOLUTION"
[[ -n "$VIRTUAL_DESKTOP" ]] && echo "  ✅ Virtual Desktop: $VIRTUAL_DESKTOP"
echo
echo "Launch games:"
echo "  $WINEPREFIX/run-game game.exe"
echo "  $WINEPREFIX/run-game -r 1920x1080 game.exe"
echo "  $WINEPREFIX/run-game -v 2560x1440 game.exe"
echo
echo "Manage resolution:"
echo "  $WINEPREFIX/set-resolution set 1920x1080"
echo "  $WINEPREFIX/set-resolution virtual 2560x1440"
echo "  $WINEPREFIX/set-resolution auto"
echo
