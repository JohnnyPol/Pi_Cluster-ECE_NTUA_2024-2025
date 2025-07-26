# HPC Team Documentation
- [Structure of Cluster](#Structure-of-Cluster)
- [Operating System](#operating-system)
- [NFS Setup](#NFS-Setup)
- [Ansible](#Ansible)
- [NIS](#NIS)
- [SLURM](#SLURM)
- [Deployment Diagram](#Deployment-Diagram)

---
# Structure of Cluster

Our team has developed a high-performance computing (HPC) cluster using 16 Raspberry Pi 4 devices. The cluster is composed of:

- **14 worker nodes (clients)**
- **1 master node**
- **1 login node**

The worker nodes are splitted in two different teams(each one of 8 pis) with names red and blue.

### Access Architecture

To access the worker nodes, users must follow a multi-hop SSH process:

1. Connect to the **login node**.
2. From the login node, SSH into the **master node** (`hpc_master`).
3. From the master node, SSH into the desired **worker (client) node**.

Each step is performed securely using SSH (`Secure Shell`), ensuring safe and authenticated access throughout the cluster.

### Project Objective

The primary objective of this project is to execute and evaluate parallel programs on the Raspberry Pi cluster. Specifically, we aim to:

- Run standardized parallel benchmarks such as the [NAS Parallel Benchmarks (NPB)](https://www.nas.nasa.gov/software/npb.html).
- Measure and analyze the performance of the cluster using graphical profiling and monitoring tools.
- Assess the scalability and efficiency of the cluster in handling compute-intensive tasks.

# Operating System
The hard disk that is supported in the login node has Ubuntu 24.04, since it is certified well working in Raspberry Pi 4 and it can accomodate the facilities of Slurm,Ansible,etc. For all the other pis PXE BOOT is used, a process which allows a computer to boot an operating system over the network instead of a local storage like a flash disk. Firstly, we enabled PXE boot in order Network Iinterface (NIC) and suitable PXE firmware to take action. Furthermore, a client sents a DHCP Request(specifically **DHCPDISCOVER**) broadcast on the network asking for an ip address,location of the boot server and a boot file name. A PXE boot server then provides as an answer a TFTP server IP and a boot file(i.e pxelinux.0). The client then contacts the TFTP server and downloads the bootloader file. Inside this file, we can find a config file(i.epxelinux.cfg/default) which tells the client what OS/kernel/initrd to load ad kernel-command-line arguments. Lastly, the linux kernel is downloaded along with the initial RAM disk and both of them are loaded into memeory, a fact which enables the booting into the desired OS. In conclusion, PXE boot allowas a machine to:
1. Get IP and boot info via DHCP
2. Download bootloader via TFTP
3. Load kernel and OS image
4. Boot over the network
   
For code details please see this [file](pxe_notes.pdf) and for the script that automates the installation of a specified APT package into multiple chrooted Linux system images stored under /mnt/netboot_common/nfs see [this file](install_package_to_all_images.sh) .
(Note : DHCP server is a network server that automatically assigns IP addresses and other network configuration parameters to devices on a network and TFTP is a simplified file transfer service that allows devices to exchange files across a network)

# NFS Setup
Every Raspberry Pi device sees the same disk via NFS. NFS, or Network File System, is a protocol that allows users to access and manage files on a remote computer as if they were stored locally. It enables file sharing across a network, making it easier to collaborate and access data from different devices. The shared directory is /mnt/hpc_shared. Additionally, for the setups of NFS, we firstly install NFS Server on login node and then create the shared directory previously mentioned. Then we configure the /etc/exports and afterwards we export ans start the NFS Server. Lastly we setup the NFS Clients on every compute node(i.e red3) by mounting them on the shared directory and we make it persistent on reboot by edit the /etc/fstab file. For more code information make sure to look in [this file](NFS_Setup)

# Ansible
Ansible is an open-source IT automation tool that allows you to:
* Configure systems (e.g., install software, set environment variables)
* Deploy applications (e.g., push your app to remote servers)
* Orchestrate tasks across multiple machines (e.g., rolling updates, cloud provisioning)
This tool was mainly used so as to create the shared user directory and NIS clients which are going to be discussed in the next section of the documentation. Ansible supports .yml formats and it could be used for every other part that could have been automated like the creation of nfs clients.

# NIS
NIS (Network Information Service) is a client-server directory service protocol used for centralized management of user and system information in a Unix or Linux network. Via NIS we can manage user and group accounts, hostnames, network configuration, etc. The primary architecture of NIS follwos the master slave model. The first role is played by NIS Server which stores and serves the centralized database from which the NIS Clients query for the information we talked about previously. The main link the setup was based on is [this](#https://help.ubuntu.com/community/SettingUpNISHowTo). For automation we created an Ansible script where you can find [here](ansible_scripts)

# SLURM

# Deployment Diagram 
In order to create a well-visualized result of our work, we created a deployment diagram following the rules in [this link](https://www.geeksforgeeks.org/system-design/deployment-diagram-unified-modeling-languageuml/) : 
<img width="1548" height="1021" alt="DeploymentDiagram" src="https://github.com/user-attachments/assets/354a4649-e811-4e4f-bbfc-25f2b9f6cf58" />


