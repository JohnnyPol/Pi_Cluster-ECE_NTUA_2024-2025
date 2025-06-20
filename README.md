# Pi_Cluster-ECE_NTUA_2024-2025

```ssh -p 2222 ubuntu@147.102.3.83```

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

## Deployment Diagram 
Following the steps of [this](https://www.geeksforgeeks.org/deployment-diagram-unified-modeling-languageuml/) article

## Links that may be useful and we may need to reference
[Git Repository Similar Project](https://github.com/projectRaspberry/wipi) <br>
[Article for Slurm](https://www.howtoraspberry.com/2022/03/how-to-build-an-hpc-high-performance-cluster-with-raspberry-pi-computers/) <br>
[Another Article for Slurm ](https://medium.com/@hghcomphys/building-slurm-hpc-cluster-with-raspberry-pis-step-by-step-guide-ae84a58692d5)<br>
[PDF of HPC Cluster Documentation](https://wr.informatik.uni-hamburg.de/_media/teaching/sommersemester_2021/ps-21_rasperry-pi-cluster.pdf) <br>
[PDF Slides (Probably not Useful)](https://archive.fosdem.org/2020/schedule/event/rpi_cluster/attachments/slides/3635/export/events/attachments/rpi_cluster/slides/3635/Introducing_HPC_with_a_Raspberry_Pi_Cluster.pdf) <br> 
[Article for NFS](https://www.howtoraspberry.com/2020/10/how-to-make-network-shared-storage-with-a-raspberry/) <br>
[Article for the Cluster Setup](https://jackyko1991.github.io/journal/Cluster-Setup-2.html) <br>
[Another Article for Cluster](https://glmdev.medium.com/building-a-raspberry-pi-cluster-784f0df9afbd) <br>
[Slurm Documentation](https://slurm.schedmd.com/documentation.html) <br>
[Useful YouTube Video for Slurm](https://www.youtube.com/watch?v=YZbRnrfECfo) <br>
[Slurm Installation Repository Tutorial](https://github.com/ReverseSage/Slurm-ubuntu-20.04.1) <br>
[Slurm Configuration Generator Tool](https://slurm.schedmd.com/configurator.html) <br>


## Slurm setup (small specification so we don't forget)
1. Install chrony instead of NTP in every node for time synchronization
```bash
sudo apt update
sudo apt install chrony
```
2. Edited the `/etc/chrony/chrony.conf` file and added these lines:
In hpc_master:
```bash
allow 192.168.2.0/24

# Default Ubuntu NTP servers are okay
server ntp.ubuntu.com iburst

local stratum 10
```
In worker nodes first comment out every line starting with `pool` or `server` and then:
```bash
# Use master Pi as NTP server
server 192.168.2.117 iburst
```
3. In every node restart and enable the chrony service (first for hpc_master):
```bash
systemctl restart chrony
systemctl enable chrony
```
4. Run `chronyc sources`, you should get the below results:

In hpc_master:
![Screenshot from 2025-04-09 17-49-46](https://github.com/user-attachments/assets/8fbb0299-b3a3-4e4c-9dc1-1bf6f809df82)

In worker nodes:
![Screenshot from 2025-04-09 17-49-32](https://github.com/user-attachments/assets/7d3ce405-c260-4d62-b129-59c6d04ecf9f)

## Grafana & Prometheus & Node Exporter
[Installation Tutorial](https://tecadmin.net/how-to-setup-prometheus-and-grafana-on-ubuntu/)



