# Package Installation – Raspberry Pi HPC Cluster

### Purpose

This folder contains the utility **install_package_to_all_images.sh**, a script designed to **install a software package into all system images** used by the Raspberry Pi HPC cluster (typically stored under `/mnt/netboot_common/nfs`).

It automates the process of updating each image and installing a specified package inside its chroot environment — ensuring all worker nodes have the same software dependencies.

---

### Script Overview

**Script:** `install_package_to_all_images.sh`
**Location:** `Login Node`

The script:

1. Must be run with **root privileges**.
2. Checks whether the given package exists in the system’s APT repositories.
3. Iterates through all cluster image directories (e.g. `red*`, `blue*`) under `/mnt/netboot_common/nfs/`.
4. Mounts essential filesystems (`/proc`, `/sys`, `/dev`, `/run`) into each image.
5. Executes `apt update` and installs the requested package inside each image’s chroot environment.
6. Cleans up by unmounting all filesystems after installation.

---

### Why This Is Needed

If you don't want to give your workers internet access this is a good alternative. In this HPC setup, each worker node boots from a shared image on the master node (via NFS and PXE).
When a new package (e.g. `htop`, `python3-numpy`, `gcc`) needs to be added cluster-wide, it must be installed into all base images.

This script makes that process simple and consistent — you just specify the package name once, and it updates all relevant images.

---

### Usage

**Run as root:**

```
sudo ./install_package_to_all_images.sh <package_name>
```

**Example:**

```
sudo ./install_package_to_all_images.sh htop
```

This will:

* Check that the package `htop` exists in the repositories.
* Mount each image (e.g. `/mnt/netboot_common/nfs/red01`, `/mnt/netboot_common/nfs/blue01`, etc.).
* Run `apt update && apt install -y htop` inside each image.
* Unmount all temporary filesystems and move to the next image.