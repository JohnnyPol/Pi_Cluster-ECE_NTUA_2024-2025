# Network (PXE) Boot
## Intuition and Necessity
Via PXE Boot Raspberry Pi devices are allowed to boot through network with no SD card required. A central Ubuntu server provides boot files via **TFTP** and the root filesystem via **NFS** enabling easy provisioning and centralized maintenance for many Pis. Furthermore, it offers a single source of truth, denoting that if an update occurs on rootfs of the server all devices can inherit the change in the next booting. On the other hand, it eases the process of adding new devices to the current cluster by creating per-device directories and a simple symlink. Normally, a device requests an IP address from a  DHCP server and via TFTP it downloads bootloader and kernel. Lastly, the kernel mounts its root filesystem over NFS. Especially for the Raspberry Pi, its firmware supports the above process natively and request boot file from the TFTP server(**start4.elf**,**kernel\*.img** and **cmdline.txt**) and afterwards it utilizes the information of **cmdline.txt** to mount the root filesystem from the NFS shared on the network.
## Prerequisites
Prior to setup, it is necessary to obtain the DHCP/TFTP and NFS-kernel server into the Ubuntu server and for each device the name/ID,MAC/Serial address should be known. Moreover, we will need a TFTP root directory on the ubuntu server and on each pi client one NFS directory along iwth a TFTP symlink named after the PI's serial pointing to that device's boot/ directory.
## Step-by-Step Setup
1. Use directory `/mnt/netboot2/nfs` as TFTP root directory. To do so we need to change the root TFTP directory(this stands for the directory from which the TFTP server serves files). For this, visit `/etc/default/tftp-hpa` file and change the TFTP_DIRECTORY to the desired. For our cluster:
```bash
TFTP_DIRECTORY="/mnt/netboot2/nfs"
```
When a Pi Client is requesting boot files during network boot, the tft-hpa will find them on the aforementioned directory.

2. Download Raspberry Pi OS Lite Image on Clients
```bash
cd /mnt/netboot2
wget -O raspios_lite_armhf_latest.img.xz https://downloads.raspberrypi.org/raspios_lite_armhf_latest
unxz raspios_lite_armhf_latest.img.xz
```
For Ubuntu Server images, unzipping is not necessary since we typically get `.iso` files directly. 

3. Mount the boot and root partitions from the image
```bash
cd /mnt/netboot2
kpartx -a -v raspios_lite_armhf_latest.img
mkdir bootmnt
mkdir rootmnt
mount /dev/mapper/loop0p1 ./bootmnt/
mount /dev/mapper/loop0p2 ./rootmnt/
```
More specifically, `kpartx` command reads the partition table from the image provided and creates device files for the partitions in /dev/mapper. In our case it will create a `/dev/mapper/loop2p1` and `/dev/mapper/loop2p2` loop devices with the /boot and /partitions of the image, while bootmnt and rootmnt are just helper directories.

4. Suppose that our client machine is `red1`. Its serial number and MAC address are `bfb94a46` and `e4:5f:01:f6:07:87` respectively. So the next step is to export these variables inside `/mnt/netboot2` directory.
```bash
cd /mnt/netboot2
PI_SERIAL=bfb94a46
PI_MAC=e4:5f:01:f6:07:87
PI_NAME=red1
SERVER_IP=192.168.2.1
```
5. Copy the mounted Image
```bash
cd /mnt/netboot2
mkdir ./nfs/${PI_NAME}
cp -a ./rootmnt/* ./nfs/${PI_NAME}
cp -a ./bootmnt/* ./nfs/${PI_NAME}/boot
```
The second `cp` command will output an error for the `issue.txt` and `overlays`, which are for now broken symbolic links. To fix this, `cd ./nfs/${PI_NAME}/boot` and delete them and copy them again from the `/mnt/netboot2/bootmnt` directory. All in all:
```bash
cd /mnt/netboot2/nfs/${PI_NAME}/boot
rm issue.txt overlays
cp /mnt/netboot2/bootmnt/issue.txt .
cp -r /mnt/netboot2/bootmnt/overlays .
```
At this point inside `/mnt/netboot2` directory we can unmount `bootmnt` and `rootmnt`.

6.
