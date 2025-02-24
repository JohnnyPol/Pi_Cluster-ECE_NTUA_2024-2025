#!/bin/bash

# Ensure the script is run as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root."
   exit 1
fi

# Prompt the user for the package name
read -p "Enter the package name to install: " PACKAGE

# Check if the package exists in the apt cache
if apt-cache show "$PACKAGE" > /dev/null 2>&1; then
    echo "Package '$PACKAGE' found in repositories."
else
    echo "Error: Package '$PACKAGE' does not exist in repositories."
    exit 1
fi

# Define the base directory where images are stored
IMAGE_DIR_BASE="/mnt"
echo "Installing package '$PACKAGE' into images under $IMAGE_DIR_BASE ..."

# Iterate over each directory in /mnt
for IMAGE in "$IMAGE_DIR_BASE"/*; do
  if [ -d "$IMAGE" ]; then
    echo "Processing image: $IMAGE"
    
    # Mount necessary filesystems into the chroot environment
    mount --bind /proc "$IMAGE/proc"
    mount --bind /sys "$IMAGE/sys"
    mount --bind /dev "$IMAGE/dev"
    
    # Update the package list and install the package inside the chroot
    chroot "$IMAGE" apt-get update
    chroot "$IMAGE" apt-get install -y "$PACKAGE"
    
    # Unmount the bound filesystems
    umount "$IMAGE/proc"
    umount "$IMAGE/sys"
    umount "$IMAGE/dev"
  fi
done

echo "Package installation complete for all images."
