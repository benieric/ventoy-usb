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
  read -rp "Enter Ventoy mount point (leave empty to auto-detect): " VENTOY_MOUNT
  if [[ -z "$VENTOY_MOUNT" ]]; then
    # Auto-detect Ventoy mount
    VENTOY_MOUNT=$(lsblk -o LABEL,MOUNTPOINT | awk '$1=="Ventoy"{print $2}' | head -1)
    if [[ -z "$VENTOY_MOUNT" ]]; then
      echo "❌ No Ventoy mount point found. Please mount the Ventoy USB first."
      exit 1
    fi
    echo "Auto-detected Ventoy mount at: $VENTOY_MOUNT"
  fi
  read -rp "Enter directory containing ISO files: " ISO_DIR
  if [[ -z "$ISO_DIR" ]]; then
    echo "❌ ISO directory cannot be empty."
    exit 1
  fi
else
  echo "Usage: $0 [ventoy_mount_point] [iso_directory]"
  echo "If no arguments provided, runs in interactive mode."
  echo "Example: $0 /mnt/ventoy /./isos"
  exit 1
fi

# Check if mount point exists and is a directory
if [[ ! -d "$VENTOY_MOUNT" ]]; then
  # Try to find and mount Ventoy partition if mount point doesn't exist
  VENTOY_PART=$(lsblk -o NAME,LABEL --noheadings | awk '$2=="Ventoy"{print $1}' | sed 's/[^a-zA-Z0-9]*//g' | head -1)
  if [[ -n "$VENTOY_PART" ]]; then
    echo "Mount point $VENTOY_MOUNT not found. Attempting to mount Ventoy partition /dev/$VENTOY_PART to $VENTOY_MOUNT..."
    sudo mkdir -p "$VENTOY_MOUNT"
    if sudo mount "/dev/$VENTOY_PART" "$VENTOY_MOUNT"; then
      echo "✅ Mounted Ventoy at $VENTOY_MOUNT"
    else
      echo "❌ Failed to mount /dev/$VENTOY_PART to $VENTOY_MOUNT"
      exit 1
    fi
  else
    echo "❌ Ventoy mount point $VENTOY_MOUNT does not exist or is not a directory, and no Ventoy partition found to mount"
    exit 1
  fi
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
sudo cp -v "$ISO_DIR"/*.iso "$VENTOY_MOUNT"/

echo "🔄 Syncing data to USB..."
sync

echo "✅ ISO files copied successfully!"