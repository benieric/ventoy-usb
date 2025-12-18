#!/usr/bin/env bash
set -euo pipefail
echo "🚀 Ventoy USB Installer Script"

# Check for version argument
if [[ $# -gt 0 ]]; then
  VENTOY_VERSION="$1"
  echo "Using specified Ventoy version: $VENTOY_VERSION"
else
  echo "Fetching latest Ventoy version..."
  VENTOY_VERSION=$(curl -s https://api.github.com/repos/ventoy/Ventoy/releases/latest | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/')

  if [[ -z "$VENTOY_VERSION" ]]; then
    echo "❌ Failed to retrieve Ventoy version. Check your internet connection."
    exit 1
  fi
fi

VENTOY_URL="https://github.com/ventoy/Ventoy/releases/download/$VENTOY_VERSION/ventoy-$VENTOY_VERSION-linux.tar.gz"

echo "📥 Downloading Ventoy $VENTOY_VERSION..."
curl -L -o ventoy.tar.gz "$VENTOY_URL"

if [[ ! -f ventoy.tar.gz ]] || [[ ! -s ventoy.tar.gz ]]; then
  echo "❌ Download failed. Check your internet connection or try again later."
  exit 1
fi

echo "📦 Extracting Ventoy..."
tar -xzf ventoy.tar.gz

if [[ ! -d "ventoy-$VENTOY_VERSION" ]]; then
  echo "❌ Extraction failed."
  exit 1
fi

cd "ventoy-$VENTOY_VERSION"

echo "🔍 Detecting removable devices..."
echo

lsblk -o NAME,TRAN,SIZE,MODEL,MOUNTPOINT | grep -E "usb|NAME"

echo
read -rp "Enter USB device (e.g. /dev/sdb): " DEVICE

if [[ ! -b "$DEVICE" ]]; then
  echo "❌ $DEVICE is not a valid block device"
  exit 1
fi

if ! lsblk -o TRAN "$DEVICE" | tail -n +2 | grep -q usb; then
  echo "❌ $DEVICE does not appear to be a USB device"
  exit 1
fi

echo
echo "⚠️  WARNING: This will ERASE ALL DATA on $DEVICE"
read -rp "Type YES to continue: " CONFIRM

if [[ "$CONFIRM" != "YES" ]]; then
  echo "Aborted."
  exit 1
fi

echo
read -rp "Do you want to download ISO files from URLs first? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  read -rp "Enter ISO URLs separated by spaces: " -a ISO_URLS
  TEMP_ISO_DIR=$(mktemp -d)
  echo "📥 Downloading ISOs to $TEMP_ISO_DIR..."
  for url in "${ISO_URLS[@]}"; do
    filename=$(basename "$url")
    echo "Downloading $filename..."
    curl -L -o "$TEMP_ISO_DIR/$filename" "$url"
  done
  echo "✅ ISO downloads complete."
fi

echo
echo "🚀 Installing Ventoy on $DEVICE..."
sudo ./Ventoy2Disk.sh -i "$DEVICE"

echo "✅ Ventoy installed successfully."

sleep 3

VENTOY_MOUNT=$(lsblk -o LABEL,MOUNTPOINT | awk '$1=="Ventoy"{print $2}')

if [[ -z "$VENTOY_MOUNT" ]]; then
  echo "❌ Could not locate Ventoy mount point"
  exit 1
fi

echo "📂 Ventoy mounted at: $VENTOY_MOUNT"

if [[ -n "${TEMP_ISO_DIR:-}" ]]; then
  ./ventoy-copy-isos.sh "$VENTOY_MOUNT" "$TEMP_ISO_DIR"
  rm -rf "$TEMP_ISO_DIR"
else
  echo
  read -rp "Optional: directory containing ISO files (leave empty to skip): " ISO_DIR

  if [[ -n "$ISO_DIR" ]]; then
    if [[ ! -d "$ISO_DIR" ]]; then
      echo "❌ Directory does not exist"
      exit 1
    fi

    ./ventoy-copy-isos.sh "$VENTOY_MOUNT" "$ISO_DIR"
  fi
fi

echo "🔄 Syncing data to USB..."
sync

echo
echo "🎉 Ventoy USB is ready!"
echo "➡️  Boot from this USB and select an ISO to install."

# Cleanup
cd ..
rm -rf "ventoy-$VENTOY_VERSION" ventoy.tar.gz
