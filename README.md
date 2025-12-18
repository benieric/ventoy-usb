# Ventoy USB Setup Script

A quick setup script to install Ventoy on a USB drive and optionally copy ISO files.

## Overview

[Ventoy](https://github.com/ventoy/Ventoy) is an open-source tool that lets you create bootable USB drives capable of booting multiple ISO images without reformatting. Traditionally, you'd need to burn one ISO at a time using tools like Rufus. Ventoy simplifies this by installing a universal bootloader once, then allowing you to copy ISOs directly to the drive.

This repository provides automated scripts to:
- Download and install the latest Ventoy on your USB drive
- Optionally download ISOs from URLs or copy from local directories
- Add more ISOs later with a reusable script

No manual partitioning, formatting, or ISO burning—just run the script and you're ready to boot any OS!

## Where to Find ISO Files

- **Linux Distributions**: [Distrowatch](https://distrowatch.com/) - Browse and download popular Linux distros
- **Windows ISOs**: [Microsoft Software Download](https://www.microsoft.com/en-us/software-download/) - Official Windows installation media
- **Ubuntu**: [ubuntu.com/download](https://ubuntu.com/download/desktop)
- **Fedora**: [getfedora.org](https://getfedora.org/)
- **Arch Linux**: [archlinux.org/download](https://archlinux.org/download/)

Note: The script supports downloading ISOs directly from URLs if you provide them during setup.

## Warning

This script will **erase all data** on the selected USB drive. Make sure to back up any important data before proceeding.

## Requirements

- Linux system
- `curl` for downloading
- `lsblk` for device detection
- `sudo` access for installing Ventoy
- Internet connection for downloading Ventoy

Clone this repository:

```bash
git clone https://github.com/benieric/ventoy-usb.git
cd ventoy-usb
```

## Quick Start

Run the main quick start script and choose your action:

```bash
./ventoy.sh
```

This will prompt you to either setup a new Ventoy USB or copy ISOs to an existing Ventoy USB.

## Ventoy USB Setup

1. Run the ventoy USB setup script (optionally specify a Ventoy version):
   ```bash
   ./ventoy-install.sh [version]
   ```
   Examples:
   - `./ventoy-install.sh` (uses latest version)
   - `./ventoy-install.sh 1.0.95` (uses specific version)

2. Follow the interactive prompts:
   - Select the USB device (e.g., `/dev/sdb`)
   - Confirm the operation (type "YES")
   - Optionally download ISO files from URLs
   - Optionally provide a local directory with ISO files (e.g., `./isos`)

## Add ISO Files to Ventoy

Use the `ventoy-add-isos.sh` script to add more ISO files to an existing Ventoy USB:

```bash
./ventoy-add-isos.sh /mnt/ventoy ./isos
```

Or run it interactively:

```bash
./ventoy-add-isos.sh
```

This script can be reused anytime to add ISOs without reinstalling Ventoy.

## Using the Ventoy USB

Once setup is complete, your USB drive is ready to boot multiple operating systems. Here's how to use it:

1. **Insert the USB** into the target computer and restart it.

2. **Enter BIOS/UEFI Setup**:
   - Common keys: F2, F10, F12, Del, or Esc (check your computer's manual).
   - Navigate to the "Boot" or "Boot Order" menu.

3. **Change Boot Order**:
   - Set the USB drive as the first boot device.
   - Save changes and exit (usually F10 or the "Save" option).

4. **Boot from Ventoy**:
   - The computer will boot from the USB, and Ventoy's menu will appear.
   - Use arrow keys to select an ISO file.
   - Press Enter to boot into the selected operating system.

5. **Install or Use the OS**:
   - Follow the on-screen instructions for installation or live environment.
   - For Windows/Linux installs, select the USB as the installation media when prompted.

**Tips**:
- If Ventoy menu doesn't appear, ensure Secure Boot is disabled in UEFI (for some systems).
- You can add/remove ISOs anytime using `ventoy-add-isos.sh` without reinstalling Ventoy.
- The USB remains bootable until you reformat it manually.

## License

This script is provided as-is. Ventoy itself is licensed under the GPL v3.0.
