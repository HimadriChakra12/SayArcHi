#!/usr/bin/env bash
# wine-setup-gaming-enhanced.sh - Complete gaming configuration with all runtimes
# Version: 2.0
set -euo pipefail

# ============================================================================
# Configuration
# ============================================================================
WINEPREFIX="${1:-}"
RESOLUTION=""
VIRTUAL_DESKTOP=""
SKIP_DXVK=0
SKIP_ASYNC=0
SKIP_DOTNET=0
SKIP_VCREDIST=0
QUICK_MODE=0

# ============================================================================
# Progress Tracking
# ============================================================================
TOTAL_STEPS=0
CURRENT_STEP=0

show_progress() {
  local message="$1"
  CURRENT_STEP=$((CURRENT_STEP + 1))
  local percent=$((CURRENT_STEP * 100 / TOTAL_STEPS))
  echo
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "[$CURRENT_STEP/$TOTAL_STEPS] ($percent%) $message"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

# ============================================================================
# Parse Arguments
# ============================================================================
show_usage() {
  cat <<EOF
Usage: $0 PREFIX [OPTIONS]

Complete gaming setup with all runtimes, DXVK, VKD3D, and performance optimizations.

Arguments:
  PREFIX                 Wine prefix path (required)

Options:
  --resolution WxH       Set default resolution (e.g., 1920x1080)
  --virtual WxH          Enable virtual desktop mode
  --no-dxvk             Skip DXVK installation
  --no-async            Disable DXVK async shaders
  --no-dotnet           Skip .NET Framework installation
  --no-vcredist         Skip Visual C++ redistributables
  --quick               Quick mode (minimal runtimes only)
  -h, --help            Show this help

Examples:
  $0 ~/.wine-games
  $0 ~/.wine-games --resolution 1920x1080
  $0 ~/.wine-games --virtual 2560x1440 --quick
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
    --no-dotnet) SKIP_DOTNET=1; shift ;;
    --no-vcredist) SKIP_VCREDIST=1; shift ;;
    --quick) QUICK_MODE=1; shift ;;
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

# Calculate total steps
TOTAL_STEPS=10  # Base steps
[[ "$SKIP_DXVK" -eq 0 ]] && TOTAL_STEPS=$((TOTAL_STEPS + 2))
[[ "$SKIP_DOTNET" -eq 0 ]] && TOTAL_STEPS=$((TOTAL_STEPS + 5))
[[ "$SKIP_VCREDIST" -eq 0 ]] && TOTAL_STEPS=$((TOTAL_STEPS + 7))

echo "╔════════════════════════════════════════╗"
echo "║   Wine Gaming Setup v2.0               ║"
echo "║   Enhanced Edition                     ║"
echo "╚════════════════════════════════════════╝"
echo
echo "Prefix: $WINEPREFIX"
[[ -n "$RESOLUTION" ]] && echo "Resolution: $RESOLUTION"
[[ -n "$VIRTUAL_DESKTOP" ]] && echo "Virtual Desktop: $VIRTUAL_DESKTOP"
[[ "$QUICK_MODE" -eq 1 ]] && echo "Mode: Quick (minimal runtimes)"
echo
echo "Total installation steps: $TOTAL_STEPS"
echo

export WINEPREFIX

# ============================================================================
# Helper Functions
# ============================================================================
install_package() {
  local package="$1"
  local description="$2"
  
  echo "📥 Installing $description..."
  echo "   Package: $package"
  
  if winetricks -q "$package" 2>&1 | tee /tmp/winetricks.log | grep -E "(Executing|Downloading|Installing|Extracting)" | while read -r line; do
    echo "   → $line"
  done; then
    echo "✅ $description installed successfully"
    return 0
  else
    if grep -q "already installed" /tmp/winetricks.log 2>/dev/null; then
      echo "ℹ️  $description already installed"
      return 0
    else
      echo "⚠️  $description installation completed with warnings"
      return 0
    fi
  fi
}

install_package_quiet() {
  local package="$1"
  local description="$2"
  
  echo "📥 Installing $description..."
  if winetricks -q "$package" >/dev/null 2>&1; then
    echo "✅ Installed"
  else
    echo "⚠️  Warning during installation"
  fi
}

# ============================================================================
# Core Dependencies
# ============================================================================
show_progress "Installing core dependencies"

echo "📦 Installing core Windows components..."
install_package_quiet "corefonts" "Core Fonts"
install_package_quiet "tahoma" "Tahoma Font"
install_package_quiet "liberation" "Liberation Fonts"

# ============================================================================
# Visual C++ Redistributables (All Versions)
# ============================================================================
if [[ "$SKIP_VCREDIST" -eq 0 ]]; then
  show_progress "Installing Visual C++ 2005 Redistributable"
  install_package "vcrun2005" "Visual C++ 2005 (vcrun2005)"
  
  show_progress "Installing Visual C++ 2008 Redistributable"
  install_package "vcrun2008" "Visual C++ 2008 (vcrun2008)"
  
  show_progress "Installing Visual C++ 2010 Redistributable"
  install_package "vcrun2010" "Visual C++ 2010 (vcrun2010)"
  
  show_progress "Installing Visual C++ 2012 Redistributable"
  install_package "vcrun2012" "Visual C++ 2012 (vcrun2012)"
  
  show_progress "Installing Visual C++ 2013 Redistributable"
  install_package "vcrun2013" "Visual C++ 2013 (vcrun2013)"
  
  show_progress "Installing Visual C++ 2015-2022 Redistributable"
  install_package "vcrun2015" "Visual C++ 2015 (vcrun2015)"
  
  show_progress "Installing Visual C++ 2019-2022 Redistributable"
  install_package "vcrun2019" "Visual C++ 2019-2022 (vcrun2019)"
else
  echo "⏭️  Skipping Visual C++ redistributables (--no-vcredist)"
fi

# ============================================================================
# .NET Framework (All Versions)
# ============================================================================
if [[ "$SKIP_DOTNET" -eq 0 ]]; then
  if [[ "$QUICK_MODE" -eq 0 ]]; then
    show_progress "Installing .NET Framework 3.5 SP1"
    install_package "dotnet35sp1" ".NET Framework 3.5 SP1"
    
    show_progress "Installing .NET Framework 4.0"
    install_package "dotnet40" ".NET Framework 4.0"
    
    show_progress "Installing .NET Framework 4.5.2"
    install_package "dotnet452" ".NET Framework 4.5.2"
  fi
  
  show_progress "Installing .NET Framework 4.6.2"
  install_package "dotnet462" ".NET Framework 4.6.2"
  
  show_progress "Installing .NET Framework 4.8"
  install_package "dotnet48" ".NET Framework 4.8"
  
  echo "ℹ️  Note: .NET Core/.NET 5+ games require native Linux .NET runtime"
  echo "   Install with: sudo apt install dotnet-runtime-6.0 dotnet-runtime-7.0"
else
  echo "⏭️  Skipping .NET Framework (--no-dotnet)"
fi

# ============================================================================
# DirectX Components
# ============================================================================
show_progress "Installing DirectX components"

echo "📦 Installing DirectX libraries..."
install_package "d3dx9" "DirectX 9 (d3dx9)"
install_package_quiet "d3dx9_43" "DirectX 9 Update"
install_package_quiet "d3dx10" "DirectX 10"
install_package_quiet "d3dx11_43" "DirectX 11"
install_package_quiet "d3dcompiler_43" "D3D Compiler 43"
install_package_quiet "d3dcompiler_47" "D3D Compiler 47"

# ============================================================================
# Additional Gaming Libraries
# ============================================================================
show_progress "Installing additional gaming libraries"

echo "📦 Installing gaming support libraries..."
install_package_quiet "xact" "XACT (Xbox Audio)"
install_package_quiet "xinput" "XInput (Controller support)"
install_package_quiet "physx" "PhysX"
install_package_quiet "vcrun6" "Visual C++ 6.0 (legacy)"

# ============================================================================
# Install DXVK & VKD3D
# ============================================================================
if [[ "$SKIP_DXVK" -eq 0 ]]; then
  show_progress "Installing DXVK (DirectX 9/10/11 → Vulkan)"
  install_package "dxvk" "DXVK"
  
  show_progress "Installing VKD3D-Proton (DirectX 12 → Vulkan)"
  install_package "vkd3d" "VKD3D-Proton"
else
  echo "⏭️  Skipping DXVK/VKD3D (--no-dxvk)"
fi

# ============================================================================
# Apply Registry Tweaks
# ============================================================================
show_progress "Applying performance registry tweaks"

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
"VideoMemorySize"="16384"
"OffscreenRenderingMode"="fbo"
"StrictDrawOrdering"="disabled"
"Multisampling"="enabled"
"SampleCount"=dword:00000004

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
    # Try to detect from system
    if command -v lspci >/dev/null 2>&1; then
      if lspci | grep -i "vga.*nvidia" >/dev/null; then
        echo "nvidia"
      elif lspci | grep -i "vga.*amd\|vga.*radeon" >/dev/null; then
        echo "amd"
      elif lspci | grep -i "vga.*intel" >/dev/null; then
        echo "intel"
      else
        echo "unknown"
      fi
    else
      echo "unknown"
    fi
  fi
}

GPU=$(detect_gpu)
echo "🎮 Detected GPU: $GPU"

# ============================================================================
# Create Gaming Environment
# ============================================================================
show_progress "Creating gaming environment"

cat > "$WINEPREFIX/gaming-env.sh" <<EOF
#!/usr/bin/env bash
# Gaming-optimized environment for Wine prefix
# Generated by wine-setup-gaming-enhanced.sh v2.0

# Load base environment
[[ -f "$WINEPREFIX/env.sh" ]] && source "$WINEPREFIX/env.sh"

# ============================================================================
# Wine Performance Settings
# ============================================================================
export WINEESYNC=1
export WINEFSYNC=1
export STAGING_SHARED_MEMORY=1
export STAGING_WRITECOPY=1

# ============================================================================
# DXVK Configuration
# ============================================================================
export DXVK_STATE_CACHE=1
export DXVK_STATE_CACHE_PATH="\$WINEPREFIX/dxvk_cache"
export DXVK_LOG_LEVEL=none
export DXVK_LOG_PATH=none
export DXVK_CONFIG_FILE="\$WINEPREFIX/dxvk.conf"
EOF

if [[ "$SKIP_ASYNC" -eq 0 ]]; then
  echo 'export DXVK_ASYNC=1' >> "$WINEPREFIX/gaming-env.sh"
fi

cat >> "$WINEPREFIX/gaming-env.sh" <<'EOF'

# ============================================================================
# VKD3D-Proton Configuration
# ============================================================================
export VKD3D_CONFIG=dxr
export VKD3D_SHADER_CACHE_PATH="$WINEPREFIX/vkd3d_cache"
export VKD3D_FEATURE_LEVEL=12_1

# ============================================================================
# Vulkan Configuration
# ============================================================================
export VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/nvidia_icd.json:/usr/share/vulkan/icd.d/radeon_icd.x86_64.json:/usr/share/vulkan/icd.d/intel_icd.x86_64.json

EOF

# GPU-specific optimizations
case "$GPU" in
  nvidia)
    cat >> "$WINEPREFIX/gaming-env.sh" <<'EOF'
# ============================================================================
# NVIDIA Optimizations
# ============================================================================
export __GL_THREADED_OPTIMIZATION=1
export __GL_SHADER_DISK_CACHE=1
export __GL_SHADER_DISK_CACHE_PATH="$WINEPREFIX/gl_cache"
export __GL_SHADER_DISK_CACHE_SKIP_CLEANUP=1
export __GL_YIELD="USLEEP"
export __GL_SYNC_TO_VBLANK=0
export __GL_MaxFramesAllowed=1
EOF
    ;;
  amd)
    cat >> "$WINEPREFIX/gaming-env.sh" <<'EOF'
# ============================================================================
# AMD Optimizations
# ============================================================================
export mesa_glthread=true
export AMD_DEBUG=nohyperz,nofmask
export RADV_PERFTEST=aco,sam,gpl,nggc
export RADV_DEBUG=novrsflatshading
export ACO_DEBUG=perfwarn
EOF
    ;;
intel)
  cat >> "$WINEPREFIX/gaming-env.sh" <<'EOF'
# ============================================================================
# Intel UHD 620 – Resolution & DXVK Fix
# ============================================================================
export mesa_glthread=true

# Force modern GL/Vulkan reporting
export MESA_GL_VERSION_OVERRIDE=4.6
export MESA_GLSL_VERSION_OVERRIDE=460

# Prevent Intel GPU mis-detection
export DXVK_FILTER_DEVICE_NAME="Intel"

# Fix presentation & fullscreen issues
export MESA_VK_WSI_PRESENT_MODE=mailbox

# Stability
export INTEL_DEBUG=nofc
EOF
  ;;
esac

cat >> "$WINEPREFIX/gaming-env.sh" <<'EOF'

# ============================================================================
# Audio Configuration
# ============================================================================
export PULSE_LATENCY_MSEC=60
export WINE_AUDIO_FREQ=48000

# ============================================================================
# Memory & Performance
# ============================================================================
export WINE_CPU_TOPOLOGY=8:8
export MALLOC_PERTURB_=0

# ============================================================================
# Game Compatibility
# ============================================================================
export SteamGameId=0
export SteamAppId=0

# Info
echo "🎮 Gaming environment loaded for: $WINEPREFIX"
EOF

chmod +x "$WINEPREFIX/gaming-env.sh"
echo "✅ Environment created"

# Create DXVK config
cat > "$WINEPREFIX/dxvk.conf" <<'EOF'
# DXVK Configuration
# https://github.com/doitsujin/dxvk

# Performance
d3d9.maxFrameLatency = 1
d3d9.numBackBuffers = 3
dxgi.maxFrameLatency = 1
dxgi.numBackBuffers = 3
dxgi.syncInterval = 0

# Memory
d3d9.allowLowMemory = False
d3d9.memoryTrackTest = False

# Async shader compilation
dxvk.enableAsync = true
dxvk.gplAsyncCache = true
EOF

# ============================================================================
# Create Game Launcher
# ============================================================================
cat > "$WINEPREFIX/run-game" <<'LAUNCHER'
#!/usr/bin/env bash
# Game launcher with Windows version selector
# Version: 2.1

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
source "$SCRIPT_DIR/gaming-env.sh"

# ============================================================================
# Variables
# ============================================================================
RESOLUTION=""
VIRTUAL_DESKTOP=""
FULLSCREEN=0
FPS_LIMIT=""
VSYNC=0
WINVER=""

# ============================================================================
# Helpers
# ============================================================================
set_windows_version() {
  local version="$1"

  cat > /tmp/winver.reg <<REG
Windows Registry Editor Version 5.00

[HKEY_CURRENT_USER\\Software\\Wine]
"Version"="$version"
REG

  wine regedit /tmp/winver.reg >/dev/null 2>&1
  rm -f /tmp/winver.reg

  echo "🪟 Windows version: $version"
}

show_help() {
  cat <<HELP
Game Launcher v2.1

Usage:
  $0 [OPTIONS] <game.exe> [game args...]

Resolution:
  -r, --resolution WxH
  -v, --virtual WxH
  -f, --fullscreen

Performance:
  --fps-limit N
  --vsync
  --no-async
  --dxvk-hud <preset>
  --debug

Windows Version:
  --winxp
  --winvista
  --win7
  --win10
  --win11

Examples:
  $0 --win7 game.exe
  $0 --win10 --fps-limit 60 game.exe
  $0 --win11 --fullscreen game.exe
HELP
  exit 0
}

# ============================================================================
# Argument Parsing
# ============================================================================
while [[ $# -gt 0 ]]; do
  case "$1" in
    -r|--resolution)
      RESOLUTION="$2"; shift 2 ;;
    -v|--virtual|--virtual-desktop)
      VIRTUAL_DESKTOP="$2"; shift 2 ;;
    -f|--fullscreen)
      FULLSCREEN=1; shift ;;
    --fps-limit)
      FPS_LIMIT="$2"; shift 2 ;;
    --vsync)
      VSYNC=1; shift ;;
    --no-async)
      export DXVK_ASYNC=0; shift ;;
    --dxvk-hud)
      export DXVK_HUD="$2"; shift 2 ;;
    --debug)
      export WINEDEBUG=+timestamp,+fps
      export DXVK_LOG_LEVEL=info
      shift ;;
    --winxp) WINVER="winxp"; shift ;;
    --winvista) WINVER="winvista"; shift ;;
    --win7) WINVER="win7"; shift ;;
    --win10) WINVER="win10"; shift ;;
    --win11) WINVER="win11"; shift ;;
    -h|--help)
      show_help ;;
    *)
      break ;;
  esac
done

if [[ -z "$1" ]]; then
  echo "❌ No executable specified"
  show_help
fi

# ============================================================================
# Apply Settings
# ============================================================================
[[ -n "$WINVER" ]] && set_windows_version "$WINVER"

if [[ -n "$FPS_LIMIT" ]]; then
  export DXVK_FRAME_RATE="$FPS_LIMIT"
  echo "🎯 FPS limit: $FPS_LIMIT"
fi

if [[ "$VSYNC" -eq 1 ]]; then
  export __GL_SYNC_TO_VBLANK=1
  echo "🔄 VSync enabled"
fi

if [[ -n "$VIRTUAL_DESKTOP" ]]; then
  export WINE_EXPLORER_DESKTOP=shell
  export WINE_EXPLORER_DESKTOP_SIZE="$VIRTUAL_DESKTOP"
  echo "🖥️ Virtual desktop: $VIRTUAL_DESKTOP"
elif [[ -n "$RESOLUTION" ]]; then
  export WINE_GAME_RESOLUTION="$RESOLUTION"
  echo "🎮 Resolution: $RESOLUTION"
fi

if [[ "$FULLSCREEN" -eq 1 ]]; then
  unset WINE_EXPLORER_DESKTOP
  unset WINE_EXPLORER_DESKTOP_SIZE
  echo "🖼️ Fullscreen"
fi

# ============================================================================
# Launch
# ============================================================================
if command -v gamemoderun >/dev/null 2>&1; then
  echo "🚀 Launching with GameMode"
  if command -v mangohud >/dev/null 2>&1; then
    exec gamemoderun mangohud wine "$@"
  else
    exec gamemoderun wine "$@"
  fi
else
WINEDLLOVERRIDES="dxgi=n,b" exec wine "$@"
fi
LAUNCHER

chmod +x "$WINEPREFIX/run-game"
echo "✅ Launcher created: $WINEPREFIX/run-game"

# ============================================================================
# Create Resolution Manager
# ============================================================================
cat > "$WINEPREFIX/set-resolution" <<'RESMGR'
#!/usr/bin/env bash
# Resolution manager v2.0

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
source "$SCRIPT_DIR/gaming-env.sh"

case "${1:-}" in
  --help|-h|"")
    cat <<HELP
Resolution Manager v2.0

Usage: $0 <COMMAND> [RESOLUTION]

Commands:
  set WxH        Set resolution (e.g., 1920x1080)
  virtual WxH    Enable virtual desktop
  fullscreen     Disable virtual desktop
  auto           Auto-detect native resolution
  current        Show current settings
  list           List common resolutions

Examples:
  $0 set 1920x1080
  $0 virtual 2560x1440
  $0 auto
  $0 list
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
      echo "🔍 Detected resolution: $RES"
      $0 set "$RES"
    else
      echo "❌ Cannot detect resolution (xrandr not found)"
      exit 1
    fi
    ;;
  current)
    echo "Current settings for: $WINEPREFIX"
    wine reg query "HKCU\\Software\\Wine\\Explorer" /v Desktop 2>/dev/null || echo "Mode: Fullscreen"
    wine reg query "HKCU\\Software\\Wine\\Explorer\\Desktops" 2>/dev/null || true
    ;;
  list)
    cat <<LIST
Common Gaming Resolutions:

1080p (Full HD):
  1920x1080  - Standard Full HD
  1920x1200  - Full HD+ (16:10)

1440p (2K):
  2560x1440  - Standard 2K (16:9)
  2560x1600  - 2K+ (16:10)
  3440x1440  - Ultrawide 2K

4K:
  3840x2160  - Standard 4K (16:9)
  3840x2400  - 4K+ (16:10)

Lower (Performance):
  1280x720   - HD
  1366x768   - HD+
  1600x900   - HD+

Usage: $0 set <resolution>
LIST
    ;;
  *)
    echo "Unknown command: $1"
    $0 --help
    ;;
esac
RESMGR

chmod +x "$WINEPREFIX/set-resolution"
echo "✅ Resolution manager created: $WINEPREFIX/set-resolution"

# ============================================================================
# Create Diagnostics Script
# ============================================================================
cat > "$WINEPREFIX/diagnostics" <<'DIAG'
#!/usr/bin/env bash
# Gaming prefix diagnostics

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
export WINEPREFIX="$SCRIPT_DIR"

echo "╔════════════════════════════════════════╗"
echo "║   Wine Gaming Prefix Diagnostics       ║"
echo "╚════════════════════════════════════════╝"
echo
echo "Prefix: $WINEPREFIX"
echo

# System info
echo "━━━ System Information ━━━"
echo "Wine version: $(wine --version 2>/dev/null)"
echo "Winetricks: $(winetricks --version 2>/dev/null | head -n1)"
echo

# GPU info
echo "━━━ GPU Information ━━━"
if command -v lspci >/dev/null 2>&1; then
  lspci | grep -i vga
  lspci | grep -i 3d
else
  echo "lspci not available"
fi
echo

# Vulkan
echo "━━━ Vulkan Support ━━━"
if command -v vulkaninfo >/dev/null 2>&1; then
  vulkaninfo --summary 2>/dev/null | head -n 20
else
  echo "vulkaninfo not installed (install vulkan-tools)"
fi
echo

# DXVK
echo "━━━ DXVK Status ━━━"
if [[ -d "$WINEPREFIX/drive_c/windows/system32" ]]; then
  ls -lh "$WINEPREFIX/drive_c/windows/system32/d3d"*.dll 2>/dev/null | head -n 10
  echo
  ls -lh "$WINEPREFIX/drive_c/windows/system32/dxgi.dll" 2>/dev/null
else
  echo "Prefix not initialized"
fi
echo

# Installed components
echo "━━━ Installed Components ━━━"
[[ -f "$WINEPREFIX/winetricks.log" ]] && tail -n 20 "$WINEPREFIX/winetricks.log" || echo "No install log"
echo

# Cache directories
echo "━━━ Cache Directories ━━━"
du -sh "$WINEPREFIX"/*_cache 2>/dev/null || echo "No caches yet"
echo

# Performance
echo "━━━ Performance Settings ━━━"
ulimit -Hn
ulimit -Sn
echo

echo "✅ Diagnostics complete"
DIAG

chmod +x "$WINEPREFIX/diagnostics"
echo "✅ Diagnostics tool created: $WINEPREFIX/diagnostics"

# ============================================================================
# Create Readme
# ============================================================================
cat > "$WINEPREFIX/README.md" <<'README'
# Wine Gaming Prefix

This prefix has been configured for optimal gaming performance.

## Quick Start

```bash
# Launch a game
./run-game game.exe

# Launch with custom resolution
./run-game -r 1920x1080 game.exe

# Launch in virtual desktop
./run-game -v 2560x1440 game.exe

# Limit FPS
./run-game --fps-limit 60 game.exe
```

## Installed Components

- **Visual C++ Redistributables**: 2005, 2008, 2010, 2012, 2013, 2015, 2019
- **.NET Framework**: 3.5 SP1, 4.0, 4.5.2, 4.6.2, 4.8
- **DirectX**: Full D3D9/10/11 support
- **DXVK**: DirectX 9/10/11 to Vulkan translation
- **VKD3D-Proton**: DirectX 12 to Vulkan translation
- **Gaming Libraries**: XInput, XACT, PhysX

## Utilities

- `./run-game` - Launch games with performance optimizations
- `./set-resolution` - Manage display resolution
- `./diagnostics` - System and prefix diagnostics
- `./gaming-env.sh` - Environment variables (auto-loaded)

## Performance Tips

1. **GameMode**: Install `gamemode` for CPU priority boost
2. **MangoHud**: Install `mangohud` for FPS overlay
3. **Shader Caches**: Located in `*_cache/` directories
4. **DXVK Async**: Reduces shader compilation stuttering

## Troubleshooting

```bash
# Run diagnostics
./diagnostics

# Check logs
cat winetricks.log

# Test DirectX
wine dxdiag

# Clear shader cache
rm -rf dxvk_cache/ vkd3d_cache/ gl_cache/
```

## Resolution Management

```bash
# Set resolution
./set-resolution set 1920x1080

# Auto-detect
./set-resolution auto

# List common resolutions
./set-resolution list
```

## Advanced

Edit `gaming-env.sh` to customize environment variables.
Edit `dxvk.conf` to tune DXVK settings.

For more help: https://github.com/doitsujin/dxvk/wiki
README

echo "✅ README created: $WINEPREFIX/README.md"

# ============================================================================
# Check System Requirements
# ============================================================================
show_progress "Checking system configuration"

echo "🔍 System checks..."

# File descriptors
CURRENT_LIMIT=$(ulimit -Hn)
if [[ "$CURRENT_LIMIT" -lt 524288 ]]; then
  echo "⚠️  File descriptor limit is low: $CURRENT_LIMIT"
  echo "    Recommended: 524288"
  echo "    Fix: sudo sh -c 'echo \"$USER hard nofile 524288\" >> /etc/security/limits.conf'"
else
  echo "✅ File descriptor limit OK: $CURRENT_LIMIT"
fi

# Vulkan
if command -v vulkaninfo >/dev/null 2>&1; then
  echo "✅ Vulkan tools installed"
else
  echo "⚠️  Vulkan tools not found (install vulkan-tools)"
fi

# GameMode
if command -v gamemoderun >/dev/null 2>&1; then
  echo "✅ GameMode available"
else
  echo "💡 Tip: Install gamemode for better performance"
fi

# MangoHud
if command -v mangohud >/dev/null 2>&1; then
  echo "✅ MangoHud available"
else
  echo "💡 Tip: Install mangohud for FPS overlay"
fi

# ============================================================================
# Final Summary
# ============================================================================
show_progress "Setup complete!"

echo
echo "╔════════════════════════════════════════╗"
echo "║  ✅ Gaming Setup Complete!             ║"
echo "╚════════════════════════════════════════╝"
echo
echo "📦 Installed Components:"
[[ "$SKIP_VCREDIST" -eq 0 ]] && echo "  ✅ Visual C++ 2005-2019"
[[ "$SKIP_DOTNET" -eq 0 ]] && echo "  ✅ .NET Framework 3.5-4.8"
[[ "$SKIP_DXVK" -eq 0 ]] && echo "  ✅ DXVK (DirectX 9/10/11)"
[[ "$SKIP_DXVK" -eq 0 ]] && echo "  ✅ VKD3D-Proton (DirectX 12)"
echo "  ✅ DirectX libraries"
echo "  ✅ Gaming support (XInput, XACT, PhysX)"
[[ "$SKIP_ASYNC" -eq 0 ]] && echo "  ✅ DXVK async enabled"
[[ -n "$RESOLUTION" ]] && echo "  ✅ Resolution: $RESOLUTION"
[[ -n "$VIRTUAL_DESKTOP" ]] && echo "  ✅ Virtual Desktop: $VIRTUAL_DESKTOP"
echo
echo "🎮 Quick Start:"
echo "  cd $WINEPREFIX"
echo "  ./run-game game.exe"
echo "  ./run-game -r 1920x1080 game.exe"
echo "  ./run-game --fps-limit 60 --vsync game.exe"
echo
echo "🔧 Utilities:"
echo "  ./set-resolution auto          # Auto-detect resolution"
echo "  ./set-resolution list          # List common resolutions"
echo "  ./diagnostics                  # Run system diagnostics"
echo "  cat README.md                  # Full documentation"
echo
echo "📊 Performance:"
echo "  GPU: $GPU"
echo "  Shader caching: Enabled"
echo "  Async compilation: $([[ "$SKIP_ASYNC" -eq 0 ]] && echo "Enabled" || echo "Disabled")"
echo
echo "💡 Tips:"
echo "  - First game launch will compile shaders (expect stuttering)"
echo "  - Shader cache builds up over time for smoother gameplay"
echo "  - Use --dxvk-hud fps with run-game to see FPS"
echo "  - Install gamemode and mangohud for best experience"
echo
