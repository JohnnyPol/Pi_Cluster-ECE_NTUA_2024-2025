#!/bin/bash

PI_NAME="$1"
PI_SERIAL="$2"

echo "Copying and renaming ubuntu template for $PI_NAME ($PI_SERIAL)"
cp -r /mnt/netboot_common/temp_ubuntu /mnt/netboot_common/nfs/
mv /mnt/netboot_common/nfs/temp_ubuntu /mnt/netboot_common/nfs/$PI_NAME

# step 6 
echo "Appending to fstab..."
echo "192.168.2.1:/mnt/netboot_common/nfs/$PI_NAME /boot nfs defaults,vers=3 0 0" >> /mnt/netboot_common/nfs/$PI_NAME/etc/fstab

# step 7
echo "Overwritting cmdline.txt..."
echo "console=serial0,115200 console=tty1 root=/dev/nfs nfsroot=192.168.2.1:/mnt/netboot_common/nfs/$PI_NAME,vers=3 rw ip=dhcp rootwait elevator=deadline" > /mnt/netboot_common/nfs/$PI_NAME/boot/cmdline.txt

# step 9
echo "Adding symbolic link..."
cd /mnt/netboot_common/nfs
ln -s $PI_NAME/boot $PI_SERIAL
