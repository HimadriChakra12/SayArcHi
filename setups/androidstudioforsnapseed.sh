#!/usr/bin/env bash
set -e

### CONFIG ###
AVD_NAME="snapseed-emulator"
DEVICE_PROFILE="pixel_4"
ANDROID_API=34
SYSTEM_IMAGE="system-images;android-${ANDROID_API};google_apis_playstore;x86_64"
RAM_MB=2048
VM_HEAP=256
CPU_CORES=2

### CHECK USER ###
if [[ $EUID -eq 0 ]]; then
  echo "❌ Do NOT run this script as root."
  exit 1
fi

echo "🧠 Android Emulator Auto Setup (Arch Linux)"
echo "------------------------------------------"

### 1️⃣ INSTALL PACKAGES ###
echo "📦 Installing required packages..."
sudo pacman -S --needed --noconfirm \
  android-studio \
  android-sdk \
  android-sdk-platform-tools \
  android-sdk-emulator \
  qemu-full \
  libvirt \
  virt-manager

### 2️⃣ ENABLE KVM ###
echo "⚡ Enabling KVM..."
sudo modprobe kvm_intel || true
sudo usermod -aG kvm,libvirt "$USER"

if [[ ! -e /dev/kvm ]]; then
  echo "❌ KVM not available. Enable VT-x in BIOS."
  exit 1
fi

### 3️⃣ ANDROID SDK ENV ###
echo "🔧 Configuring Android SDK..."
SDK_ROOT="$HOME/Android/Sdk"

mkdir -p "$SDK_ROOT"
export ANDROID_SDK_ROOT="$SDK_ROOT"
export ANDROID_HOME="$SDK_ROOT"
export PATH="$PATH:$SDK_ROOT/emulator:$SDK_ROOT/platform-tools:$SDK_ROOT/cmdline-tools/latest/bin"

if ! grep -q ANDROID_SDK_ROOT ~/.bashrc; then
  echo "export ANDROID_SDK_ROOT=$SDK_ROOT" >> ~/.bashrc
  echo 'export PATH=$PATH:$ANDROID_SDK_ROOT/emulator:$ANDROID_SDK_ROOT/platform-tools:$ANDROID_SDK_ROOT/cmdline-tools/latest/bin' >> ~/.bashrc
fi

### 4️⃣ INSTALL SDK COMPONENTS ###
echo "⬇️ Installing Android SDK components..."
yes | sdkmanager --licenses

sdkmanager \
  "platform-tools" \
  "emulator" \
  "platforms;android-${ANDROID_API}" \
  "$SYSTEM_IMAGE"

### 5️⃣ CREATE AVD ###
echo "📱 Creating emulator: $AVD_NAME"

echo "no" | avdmanager create avd \
  -n "$AVD_NAME" \
  -k "$SYSTEM_IMAGE" \
  -d "$DEVICE_PROFILE" \
  --force

### 6️⃣ OPTIMIZE AVD CONFIG ###
AVD_DIR="$HOME/.android/avd/${AVD_NAME}.avd/config.ini"

echo "hw.ramSize=$RAM_MB" >> "$AVD_DIR"
echo "vm.heapSize=$VM_HEAP" >> "$AVD_DIR"
echo "hw.cpu.ncore=$CPU_CORES" >> "$AVD_DIR"
echo "hw.gpu.enabled=yes" >> "$AVD_DIR"
echo "hw.gpu.mode=host" >> "$AVD_DIR"
echo "hw.camera.back=emulated" >> "$AVD_DIR"
echo "hw.camera.front=emulated" >> "$AVD_DIR"
echo "disk.dataPartition.size=8G" >> "$AVD_DIR"
echo "fastboot.forceColdBoot=yes" >> "$AVD_DIR"

### 7️⃣ LAUNCH EMULATOR ###
echo "🚀 Launching emulator..."
nohup emulator \
  -avd "$AVD_NAME" \
  -gpu host \
  -no-snapshot \
  -no-boot-anim \
  -accel on \
  > /tmp/emulator.log 2>&1 &

echo
echo "✅ SETUP COMPLETE"
echo "📱 Emulator Name: $AVD_NAME"
echo "🛒 Open Play Store → Install Snapseed"
echo
echo "⚠️ Reboot once to apply KVM group permissions"
