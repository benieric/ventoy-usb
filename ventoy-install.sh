#!/usr/bin/env bash
set -euo pipefail
echo "🚀 Ventoy USB Installer Script"

# Check for version argument
if [[ $# -gt 0 ]]; then
  VENTOY_VERSION="$1"
  VENTOY_VERSION=${VENTOY_VERSION#v}  # Remove leading 'v' if present
  echo "Using specified Ventoy version: $VENTOY_VERSION"
else
  echo "Fetching latest Ventoy version..."
  VENTOY_VERSION=$(curl -s https://api.github.com/repos/ventoy/Ventoy/releases/latest | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/')
  VENTOY_VERSION=${VENTOY_VERSION#v}  # Remove leading 'v' if present

  if [[ -z "$VENTOY_VERSION" ]]; then
    echo "❌ Failed to retrieve Ventoy version. Check your internet connection."
    exit 1
  fi
fi

VENTOY_URL="https://github.com/ventoy/Ventoy/releases/download/v$VENTOY_VERSION/ventoy-$VENTOY_VERSION-linux.tar.gz"

echo "📥 Downloading Ventoy $VENTOY_VERSION..."
curl -L -o ventoy.tar.gz "$VENTOY_URL"

if [[ ! -f ventoy.tar.gz ]] || [[ ! -s ventoy.tar.gz ]]; then
  echo "❌ Download failed. Check your internet connection or try again later."
  exit 1
fi

# Verify the downloaded file is a valid tar.gz
if ! tar -tzf ventoy.tar.gz >/dev/null 2>&1; then
  echo "❌ Downloaded file is not a valid tar.gz archive. The Ventoy version or URL may be incorrect."
  echo "URL attempted: $VENTOY_URL"
  exit 1
fi

echo "📦 Extracting Ventoy..."
tar -xzf ventoy.tar.gz

if [[ ! -d "ventoy-$VENTOY_VERSION" ]]; then
  echo "❌ Extraction failed."
  exit 1
fi

cd "ventoy-$VENTOY_VERSION"

# Allow root to write to the directory
sudo chmod -R 755 .

echo "🔍 Detecting removable devices..."
# Refresh block devices
sudo udevadm trigger --subsystem-match=block --action=change
sleep 2
echo

lsblk -o NAME,TRAN,SIZE,MODEL,MOUNTPOINT | grep -E "usb|NAME"

echo
read -rp "Enter USB device (e.g. /dev/sdb): " DEVICE

if [[ ! -b "$DEVICE" ]]; then
  echo "❌ $DEVICE is not a valid block device"
  exit 1
fi

# Check device size
DEVICE_SIZE=$(lsblk -o SIZE -n "$DEVICE" | head -1)
if [[ "$DEVICE_SIZE" == "0B" ]]; then
  echo "⚠️  Warning: Device size reported as 0B. This may indicate the device is not ready or faulty."
  echo "Actual size may be different. Proceed with caution."
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
echo "🚀 Installing Ventoy on $DEVICE, this may take a few minutes ..."
# Unmount any existing partitions on the device
for part in $(lsblk -o NAME "$DEVICE" | tail -n +2 | sed 's/[^a-zA-Z0-9]//g'); do
  sudo umount "/dev/$part" 2>/dev/null || true
done
sudo ./Ventoy2Disk.sh -I "$DEVICE"

echo "✅ Ventoy installed successfully."

# Verify device is still available
if [[ ! -b "$DEVICE" ]]; then
  echo "❌ Device $DEVICE is no longer available after installation"
  echo "Try unplugging and re-plugging the USB, then run the script again."
  echo "Alternatively, check 'lsblk' for a new device name."
  exit 1
fi

# Re-read partition table
sudo partprobe "$DEVICE"

sleep 3

VENTOY_MOUNT=$(lsblk -o LABEL,MOUNTPOINT | awk '$1=="Ventoy"{print $2}')

if [[ -z "$VENTOY_MOUNT" ]]; then
  echo "Ventoy partition not auto-mounted. Attempting to mount manually..."
  VENTOY_PART=$(lsblk -o NAME,LABEL --noheadings | awk '$2=="Ventoy"{print $1}' | sed 's/[^a-zA-Z0-9]*//g' | head -1)
  if [[ -n "$VENTOY_PART" ]]; then
    sudo mkdir -p /mnt/ventoy
    sudo mount "/dev/$VENTOY_PART" /mnt/ventoy
    VENTOY_MOUNT=/mnt/ventoy
    echo "✅ Mounted Ventoy at $VENTOY_MOUNT"
  else
    echo "❌ Could not find Ventoy partition to mount"
    exit 1
  fi
fi

echo "📂 Ventoy mounted at: $VENTOY_MOUNT"

cd ..
if [[ -n "${TEMP_ISO_DIR:-}" ]]; then
  ./ventoy-add-isos.sh "$VENTOY_MOUNT" "$TEMP_ISO_DIR"
  rm -rf "$TEMP_ISO_DIR"
else
  echo
  read -rp "Optional: directory containing ISO files (leave empty to skip): " ISO_DIR

  if [[ -n "$ISO_DIR" ]]; then
    ./ventoy-add-isos.sh "$VENTOY_MOUNT" "$ISO_DIR"
  fi
fi

echo "🔄 Syncing data to USB..."
sync

echo
echo "🎉 Ventoy USB is ready!"
echo "➡️  Boot from this USB and select an ISO to install."

# Cleanup
rm -rf "ventoy-$VENTOY_VERSION" ventoy.tar.gz
