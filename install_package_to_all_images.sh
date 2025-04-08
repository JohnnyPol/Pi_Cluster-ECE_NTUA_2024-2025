#!/bin/bash

# Define color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if a package name was passed as an argument
if [ -z "$1" ]; then
    echo -e "${YELLOW}Usage: $0 <package_name>${NC}"
    exit 1
fi

PACKAGE="$1"

# Ensure the script is run as root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}This script must be run as root.${NC}"
   exit 1
fi

echo -e "${BLUE}Checking if package '${PACKAGE}' exists...${NC}"
# Check if the package exists in the apt cache
if apt-cache show "$PACKAGE" > /dev/null 2>&1; then
    echo -e "${GREEN}Package '${PACKAGE}' found in repositories.${NC}"
else
    echo -e "${RED}Error: Package '${PACKAGE}' does not exist in repositories.${NC}"
    exit 1
fi

# Define the base directory where images are stored
IMAGE_DIR_BASE="/mnt/netboot_common/nfs"
echo -e "${BLUE}Installing package '${PACKAGE}' into images under ${IMAGE_DIR_BASE}...${NC}"

# Iterate over each directory matching /mnt/netboot_common/nfs/red*
for IMAGE in "$IMAGE_DIR_BASE/red"* "$IMAGE_DIR_BASE/blue"*; do
  if [ -d "$IMAGE" ]; then
    echo -e "${YELLOW}-------------------------------${NC}"
    echo -e "${YELLOW}Processing image: ${IMAGE}${NC}"
    
    echo -e "${BLUE}Mounting necessary filesystems for chroot...${NC}"
    mount --bind /proc "$IMAGE/proc"
    mount --bind /sys "$IMAGE/sys"
    mount --bind /dev "$IMAGE/dev"
    mount --bind /run "$IMAGE/run"
    
    echo -e "${BLUE}Updating package list inside chroot at ${IMAGE}...${NC}"
    chroot "$IMAGE" apt update
    
    echo -e "${BLUE}Installing package '${PACKAGE}' inside chroot at ${IMAGE}...${NC}"
    chroot "$IMAGE" apt install -y "$PACKAGE"
    
    echo -e "${BLUE}Unmounting filesystems for ${IMAGE}...${NC}"
    umount "$IMAGE/proc"
    umount "$IMAGE/sys"
    umount "$IMAGE/dev"
    umount "$IMAGE/run"
    
    echo -e "${GREEN}Finished processing image: ${IMAGE}${NC}"
    echo -e "${YELLOW}-------------------------------${NC}"
  fi
done

echo -e "${GREEN}Package installation complete for all images.${NC}"
