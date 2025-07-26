## NFS Setup
Following [this](https://www.digitalocean.com/community/tutorials/how-to-set-up-an-nfs-mount-on-ubuntu-20-04) tutorial
###  STEP 1: Install NFS Server on the Login Node
```bash
sudo apt update
sudo apt install nfs-kernel-server
```
### STEP 2: Create a Shared Directory
Choose or create the directory you want to share (e.g., /mnt/hpc_shared):

```bash
sudo mkdir -p /mnt/shared
sudo chown nobody:nogroup /mnt/shared
sudo chmod 777 /mnt/shared  # or adjust permissions as needed
```

### STEP 3: Configure /etc/exports
Edit the file:
```bash
sudo nano /etc/exports
```
Add this line:
```bash
/mnt/shared 192.168.2.0/24(rw,sync,no_subtree_check,no_root_squash)
```
Explanation:

- `/mnt/shared` → The folder you're sharing
- `192.168.2.96/27` → IP range for compute nodes (adjust if needed)
- `rw` → Read and write access
- `sync` → Writes are flushed immediately (safer)
- `no_subtree_check` → Improves performance
- `no_root_squash` → Allows root on clients to act as root

### STEP 4: Export and Start NFS Server
```bash
sudo exportfs -a
sudo systemctl restart nfs-kernel-server
```
Confirm it's running:
```bash
sudo systemctl status nfs-kernel-server
```
### Step 5: Set Up NFS Clients on the Compute Nodes
Repeat this on each node (use Ansible preferably).

1. Install NFS client:
```bash
sudo apt update
sudo apt install nfs-common
```
2. Create the mount point:
```bash
sudo mkdir -p /mnt/hpc_shared
```
3. Mount the NFS share:
```bash
sudo mount 192.168.2.1:/mnt/hpc_shared /mnt/shared
```
Test that it works:

### STEP 6: Make It Persistent on Reboot 
On each compute node, edit /etc/fstab:
```bash
sudo nano /etc/fstab
```
Add:
```bash
192.168.2.X:/mnt/shared /mnt/shared nfs defaults 0 0
```
