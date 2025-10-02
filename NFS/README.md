# NFS Setup for the Raspberry Pi HPC Cluster

In our cluster, all nodes (**login**, **`hpc_master`**, and **compute nodes**) need access to the same files. This is essential for:

* **Consistency**: All users see the same environment, scripts, and data.
* **Job scheduling**: Slurm requires a shared filesystem so jobs launched on any node can access the same files.
* **Ease of management**: Software and datasets are stored once, not duplicated across nodes.

To achieve this, we use **NFS (Network File System)**. NFS allows one node (the **server**) to export a directory that other nodes (the **clients**) can mount as if it were local.


## Table of Contents
- [NFS Setup for the Raspberry Pi HPC Cluster](#nfs-setup-for-the-raspberry-pi-hpc-cluster)
  - [Table of Contents](#table-of-contents)
  - [What is NFS?](#what-is-nfs)
  - [Our NFS design](#our-nfs-design)
  - [Step-by-step setup](#step-by-step-setup)
    - [1) Install the NFS server](#1-install-the-nfs-server)
    - [2) Create and permission the export directory (server)](#2-create-and-permission-the-export-directory-server)
      - [Why permissions matter](#why-permissions-matter)
    - [3) Export the share (server)](#3-export-the-share-server)
      - [Choosing client IPs](#choosing-client-ips)
      - [Export options explained](#export-options-explained)
      - [Apply and start NFS](#apply-and-start-nfs)
      - [Verify the export](#verify-the-export)
    - [4) (Optional) Firewall on the server](#4-optional-firewall-on-the-server)
    - [5) Install the NFS client (on **each compute node**)](#5-install-the-nfs-client-on-each-compute-node)
      - [Mount for a quick test](#mount-for-a-quick-test)
      - [Verify the mount](#verify-the-mount)
    - [6) Make the mount persistent (clients)](#6-make-the-mount-persistent-clients)
      - [What does "persistent" mean?](#what-does-persistent-mean)
      - [What is the `/etc/fstab` file?](#what-is-the-etcfstab-file)
      - [Edit `/etc/fstab` on each compute node](#edit-etcfstab-on-each-compute-node)
      - [Explanation of the line](#explanation-of-the-line)
      - [Apply the changes without rebooting](#apply-the-changes-without-rebooting)
  - [Automation with Ansible Scripts (Server \& Clients)](#automation-with-ansible-scripts-server--clients)
    - [Files used in automation](#files-used-in-automation)
    - [Running the playbooks](#running-the-playbooks)


## What is NFS?

**NFS (Network File System)** is a protocol that allows files and directories to be shared across a network. With NFS:

* A **server** exports a directory.
* **Clients** mount this directory and access it as if it were part of their local filesystem.

This makes it possible to:

* Centralize storage in one place.
* Give multiple machines consistent access to the same files.
* Simplify management of data, software, and user environments.

NFS is widely used because it is **standard, reliable, and efficient** for regular access to shared resources in distributed systems — making it a natural choice for HPC clusters.

## Our NFS design
| Component        | Description                                                                                                                 |
| ---------------- | --------------------------------------------------------------------------------------------------------------------------- |
| **Server**       | The **login node** exports a shared directory to the cluster subnet.                                                        |
| **Export path**  | `/mnt/hpc_shared` (any path can be used, but it must be consistent).                                                        |
| **Clients**      | All compute nodes mount the share at the **same mountpoint** (`/mnt/hpc_shared`) so scripts and job configs work uniformly. |
| **Access scope** | Restricted to the private cluster subnet (`192.168.2.96/27`).                                                          |
| **Version**      | NFSv4 (recommended for simplicity and reliability).                                                                         |

## Step-by-step setup
> Replace placeholders in the commands below with your corresponding value for your setup.
>
> * `<SERVER_IP>` &rarr; login node IP (`192.168.2.1`)
> * `<SUBNET_CIDR>` &rarr; cluster subnet (`192.168.2.96/27`)

### 1) Install the NFS server
On the **login** node:
```bash
sudo apt update
sudo apt install -y nfs-kernel-server
```
This installs the NFS server service (nfs-kernel-server), which will manage the exported shared directory.

### 2) Create and permission the export directory (server)
We need to create the directory that will be shared with all nodes:
```bash
sudo mkdir -p /mnt/hpc_shared
```
#### Why permissions matter
NFS enforces filesystem permissions from the server side. The way you set ownership and mode bits on the server will directly control what clients can do.
* `chown nobody:nogroup` &rarr; sets the directory ownership to a neutral, unprivileged user.
* `chmod 0777` &rarr; allows **read/write/execute** for everyone (safe for shared project space, but not secure for private files).

This ensures all nodes can freely create and modify files inside the shared space.
```bash
sudo chown nobody:nogroup /mnt/hpc_shared
sudo chmod 0777 /mnt/hpc_shared
```

### 3) Export the share (server)

NFS exports are defined in the file `/etc/exports`. This file tells the NFS server **which directories to share**, **with whom**, and **with what permissions**.

Edit it:

```bash
sudo nano /etc/exports
```

Add the following line:

```exports
/mnt/hpc_shared <SUBNET_CIDR>(rw,sync,sec=sys,no_root_squash,no_subtree_check)
```

#### Choosing client IPs

* For **a single client**, use its IP (e.g., `192.168.2.5`).
* For **multiple clients**, use your cluster’s subnet in **CIDR notation** (e.g., `192.168.2.96/27`).

  * This allows all nodes in that range to access the share.
  * You can calculate the correct CIDR using [this tool](https://acalculate.com/network-calculators/cidr-calculator).


#### Export options explained

| Option               | Meaning                                                                                                                              |
| -------------------- | ------------------------------------------------------------------------------------------------------------------------------------ |
| **rw**               | Clients get both **read and write** access.                                                                                          |
| **sync**             | Changes are written to disk before the server replies. Safer, but slower.                                                            |
| **no_subtree_check** | Skips extra checks when accessing renamed or moved files. Improves reliability.                                                      |
| **no_root_squash**   | Lets `root` on clients act as `root` on the share. Convenient but less secure. Normally `root` is “squashed” to `nobody` for safety. |
| **sec=sys**          | Uses normal UNIX UID/GID for authentication (standard default).                                                                      |

---

#### Apply and start NFS

```bash
sudo exportfs -ra
sudo systemctl restart nfs-kernel-server
sudo systemctl enable nfs-kernel-server
```

* `exportfs -ra` &rarr; re-reads `/etc/exports` and applies changes immediately.
* `systemctl restart` &rarr; restarts the NFS server to ensure changes take effect.
* `systemctl enable` &rarr; makes the NFS service start automatically on boot.

---

#### Verify the export

```bash
sudo exportfs -v
systemctl status nfs-kernel-server
```

**Expected output:**

* `exportfs -v` should show something like:

  ```
  /mnt/hpc_shared  192.168.2.96/27(rw,wdelay,root_squash,no_subtree_check,sec=sys)
  ```
* `systemctl status` should show the service as **active (running)** without errors.

### 4) (Optional) Firewall on the server

If you use **`ufw`** (Uncomplicated Firewall), allow NFS traffic only from the cluster subnet:

```bash
sudo ufw allow from <SUBNET_CIDR> to any port nfs
sudo ufw reload
```

NFSv4 mainly uses **TCP/2049**, so this rule ensures compute nodes can connect without exposing the service to the outside world.


### 5) Install the NFS client (on **each compute node**)

Install the NFS client utilities:

```bash
sudo apt update
sudo apt install -y nfs-common
```

Create the local mountpoint (the directory where the share will appear):

```bash
sudo mkdir -p /mnt/hpc_shared
```

#### Mount for a quick test

```bash
sudo mount -t nfs -o vers=4.2,hard,intr <SERVER_IP>:/mnt/hpc_shared /mnt/hpc_shared
```

**Explanation of the command:**

* `mount` &rarr; mount a filesystem.
* `-t nfs` &rarr; specify NFS as the filesystem type.
* `-o vers=4.2,hard,intr` &rarr;

  * `vers=4.2` &rarr; use NFS protocol version 4.2 (stable, modern).
  * `hard` &rarr; if the server becomes unavailable, I/O waits (safer for data consistency).
  * `intr` &rarr; allows you to interrupt (`Ctrl+C`) a hung NFS operation.
* `<SERVER_IP>:/mnt/hpc_shared` &rarr; the export path from the server.
* `/mnt/hpc_shared` &rarr; the mountpoint on the client.

This command temporarily mounts the server’s directory so you can test access.

---

#### Verify the mount

Run the following checks:

```bash
mount | grep hpc_shared             # confirm the mount is active
touch /mnt/hpc_shared/hello_from_$(hostname)  # create a test file
ls -l /mnt/hpc_shared                # see the file from other nodes
```

If everything is correct, each compute node should be able to see files created by the others in the shared directory.


### 6) Make the mount persistent (clients)

#### What does "persistent" mean?

Right now, the NFS share is mounted only temporarily. If the client node reboots, the mount disappears.
To make it **persistent**, we configure the system so the share is mounted automatically on startup.

---

#### What is the `/etc/fstab` file?

The file **`/etc/fstab`** (Filesystem Table) lists all filesystems that should be mounted at boot time.
By adding an entry here, the OS knows to mount the NFS share automatically on every reboot.

#### Edit `/etc/fstab` on each compute node

```bash
sudo nano /etc/fstab
```

Add the following line at the end:

```fstab
# NFS shared space
<SERVER_IP>:/mnt/hpc_shared  /mnt/hpc_shared  nfs  vers=4.2,_netdev,x-systemd.automount,noatime,hard,intr  0  0
```

#### Explanation of the line

* **`<SERVER_IP>:/mnt/hpc_shared`** &rarr; the NFS export (server + directory).
* **`/mnt/hpc_shared`** &rarr; where it should be mounted locally.
* **`nfs`** &rarr; filesystem type.
* **Options:**

  * `vers=4.2` &rarr; use NFS version 4.2.
  * `_netdev` &rarr; ensures the mount happens *after* the network is up.
  * `x-systemd.automount` &rarr; mounts on first access, avoids delays if the server is down during boot.
  * `noatime` &rarr; reduces metadata writes, improving performance.
  * `hard` &rarr; retries indefinitely if the server is unavailable (important for HPC consistency).
  * `intr` &rarr; allows interrupts of hung I/O.
* **`0 0`** &rarr; disable automatic filesystem checks (fsck) for this mount.

#### Apply the changes without rebooting

```bash
sudo systemctl daemon-reload
sudo systemctl restart remote-fs.target
# or:
sudo mount -a
```

**What these do:**

* `systemctl daemon-reload` &rarr; tells systemd to reload configuration files (like updated `fstab`).
* `systemctl restart remote-fs.target` &rarr; restarts network-based mounts.
* `mount -a` &rarr; re-mounts all filesystems listed in `/etc/fstab`. Handy for testing the new entry immediately.

---

After this, your NFS share will always be mounted at `/mnt/hpc_shared` automatically on every compute node boot.

The above steps and a more general approach with more detail can be found in this [article](https://www.digitalocean.com/community/tutorials/how-to-set-up-an-nfs-mount-on-ubuntu-20-04)


## Automation with Ansible Scripts (Server & Clients)

Manually repeating the NFS setup across many nodes is time-consuming and error-prone. To avoid this, we use **Ansible playbooks** to automate the configuration of both the NFS server and all compute clients.

### Files used in automation

* [**nfs_server.yml**](./nfs_server.yml)
  Configures the **login node** as the NFS server (install package, create/export directory, apply `/etc/exports`, enable service, optional firewall).

* [**nfs_clients.yml**](./nfs_clients.yml)
  Configures all **compute nodes** as NFS clients (install package, create mountpoint, update `/etc/fstab`, mount the share).

* [**group_vars/all.yml**](./group_vars/all.yml)
  Contains the **variables** used in both playbooks (server IP, subnet, export path, mount options, etc.).

  * You can edit this file to adapt the setup to your cluster.

* [**hosts.ini**](./hosts.ini)
  Defines the **inventory**:

  * `nfs_server` group &rarr; your login node.
  * `compute_nodes` group &rarr; all compute nodes (`red1…red8`, `blue1…blue8`).

* [**ansible.cfg**](./ansible.cfg)
  Configuration file for Ansible. It specifies the default inventory and SSH key, and disables host key checks for smoother automation.

### Running the playbooks

Once you have adjusted the variables and inventory to your environment, run:

```bash
# Configure the NFS server (login node)
ansible-playbook nfs_server.yml

# Configure all compute nodes as clients
ansible-playbook nfs_clients.yml
```

You can safely rerun these commands at any time. If a node is already configured correctly, nothing changes. If something is misconfigured, Ansible will automatically correct it.

---