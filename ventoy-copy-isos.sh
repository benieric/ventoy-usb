#!/usr/bin/env bash
set -euo pipefail

echo "🚀 Ventoy ISO Copy Script"

# Check arguments
if [[ $# -eq 2 ]]; then
  VENTOY_MOUNT="$1"
  ISO_DIR="$2"
elif [[ $# -eq 0 ]]; then
  # Interactive mode
  echo "This script copies ISO files to an existing Ventoy USB drive."
  echo
  read -rp "Enter Ventoy mount point (e.g., /mnt/ventoy): " VENTOY_MOUNT
  read -rp "Enter directory containing ISO files: " ISO_DIR
else
  echo "Usage: $0 [ventoy_mount_point] [iso_directory]"
  echo "If no arguments provided, runs in interactive mode."
  echo "Example: $0 /mnt/ventoy /home/user/isos"
  exit 1
fi

# Check if mount point exists and is a directory
if [[ ! -d "$VENTOY_MOUNT" ]]; then
  echo "❌ Ventoy mount point $VENTOY_MOUNT does not exist or is not a directory"
  exit 1
fi

# Check if it's actually a Ventoy mount (optional, but good)
if ! lsblk -o LABEL,MOUNTPOINT | grep -q "Ventoy.*$VENTOY_MOUNT"; then
  echo "⚠️  Warning: $VENTOY_MOUNT does not appear to be a Ventoy mount point"
  read -rp "Continue anyway? (y/N): " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 1
  fi
fi

# Check if ISO directory exists
if [[ ! -d "$ISO_DIR" ]]; then
  echo "❌ ISO directory $ISO_DIR does not exist"
  exit 1
fi

# Check for ISO files
if ! compgen -G "$ISO_DIR/*.iso" > /dev/null; then
  echo "⚠️  No .iso files found in $ISO_DIR"
  exit 1
fi

echo "📦 Copying ISO files from $ISO_DIR to $VENTOY_MOUNT..."
cp -v "$ISO_DIR"/*.iso "$VENTOY_MOUNT"/

echo "🔄 Syncing data to USB..."
sync

echo "✅ ISO files copied successfully!"