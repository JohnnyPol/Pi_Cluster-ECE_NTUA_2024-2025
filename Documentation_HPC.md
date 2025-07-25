# HPC Team Documentation
- [Main Target and Structure of Pi's Cluster](#main-target-and-structure-of-pis-cluster)
- [Operating System](#operating-system)

---
# Main Target and Structure of the Pi Cluster

Our team has developed a high-performance computing (HPC) cluster using 16 Raspberry Pi 4 devices. The cluster is composed of:

- **14 worker nodes (clients)**
- **1 master node**
- **1 login node**

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
(Note : DHCP server is a network server that automatically assigns IP addresses and other network configuration parameters to devices on a network and TFTP is a simplified file transfer service that allows devices to exchange files across a network)
