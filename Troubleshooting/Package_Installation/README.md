**Package Installation – Raspberry Pi HPC Cluster**

---

### 📦 Purpose

This folder contains the utility **install_package_to_all_images.sh**, a script designed to **install a software package into all system images** used by the Raspberry Pi HPC cluster (typically stored under `/mnt/netboot_common/nfs`).

It automates the process of updating each image and installing a specified package inside its chroot environment — ensuring all worker nodes have the same software dependencies.

---

### ⚙️ Script Overview

**Script:** `install_package_to_all_images.sh`
**Location:** `/home/hpc_master/Package_Installation/`

The script:

1. Verifies that it is run with **root privileges**.
2. Checks whether the given package exists in the system’s APT repositories.
3. Iterates through all cluster image directories (e.g. `red*`, `blue*`) under `/mnt/netboot_common/nfs/`.
4. Mounts essential filesystems (`/proc`, `/sys`, `/dev`, `/run`) into each image.
5. Executes `apt update` and installs the requested package inside each image’s chroot environment.
6. Cleans up by unmounting all filesystems after installation.

---

### 🧠 Why This Is Needed

In this HPC setup, each worker node boots from a shared image on the master node (via NFS or PXE).
When a new package (e.g. `htop`, `python3-numpy`, `gcc`) needs to be added cluster-wide, it must be installed into all base images.

This script makes that process simple and consistent — you just specify the package name once, and it updates all relevant images.

---

### 🧩 Usage

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

---

### 🪄 Example Output (simplified)

```
Checking if package 'htop' exists...
Package 'htop' found in repositories.
Installing package 'htop' into images under /mnt/netboot_common/nfs...

Processing image: /mnt/netboot_common/nfs/red01
Mounting necessary filesystems for chroot...
Updating package list inside chroot...
Installing package 'htop' inside chroot...
Unmounting filesystems...
Finished processing image: /mnt/netboot_common/nfs/red01

Processing image: /mnt/netboot_common/nfs/blue01
...
Package installation complete for all images.
```

---

### ⚠️ Notes & Precautions

* **Run only on the master node.** The images must be accessible under `/mnt/netboot_common/nfs/`.
* **Must be executed as root** — otherwise, mounting and chroot operations will fail.
* Ensure no nodes are actively booting or updating from these images while the script is running.
* You can safely re-run the script; APT will skip already-installed packages.
* For debugging, check `/var/log/apt/history.log` inside each image if installation fails.

---

### ✅ Example Use Cases

| Use Case                      | Command                                                   |
| ----------------------------- | --------------------------------------------------------- |
| Install `htop` for monitoring | `sudo ./install_package_to_all_images.sh htop`            |
| Add Python libraries          | `sudo ./install_package_to_all_images.sh python3-numpy`   |
| Add compilers or dev tools    | `sudo ./install_package_to_all_images.sh build-essential` |
| Add network utilities         | `sudo ./install_package_to_all_images.sh net-tools`       |

---

### 📁 Related Folders

* **parallel-ssh/** → for running commands across all live worker nodes
* **Workers-Restart/** → for restarting compute nodes after image changes
* **troubleshooting/** → for checking cluster status (e.g. using `prun date`)

---

### 🧑‍💻 Author

**HPC Master Node – Raspberry Pi Cluster Project**
Maintained by: *[your name or project group if desired]*
Path: `/home/hpc_master/Package_Installation`
