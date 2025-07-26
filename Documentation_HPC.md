# HPC Team Documentation
- [Structure of Cluster](#Structure-of-Cluster)
- [Operating System](#operating-system)
- [NFS Setup](#NFS-Setup)
- [Ansible](#Ansible)
- [NIS](#NIS)
- [SLURM](#SLURM)
- [Monitoring Tools](#monitoring-tools)
- [Deployment Diagram](#Deployment-Diagram)
- [Further Details](#Further-Details)
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
Slurm (formerly Simple Linux Utility for Resource Management) is an open-source job scheduler used by many high-performance computing (HPC) clusters to manage and allocate computational resources like CPUs, memory, and GPUs across multiple users and jobs. SLURM provides the opportunity to schedule jobs to run on available nodes, allocate resources(like memory,cores), run jobs in parallel(MPI) and monitor jobs and resource usage. For more information and code check [this](Slurm_Setup.md)
<img width="903" height="483" alt="image" src="https://github.com/user-attachments/assets/564807bb-d35f-4385-8998-1032c6900ddb" />

# Monitoring Tools
In order to quantify and measure the perfromance of the system along with resource consumption, we installed Grafana and Prometheous. The latter is a time-series database and monitoring system. It collects metrics from targets at regular intervals, stores them, and allows querying and alerting based on this data. Grafana is a visualization and dashboarding tool. It lets you query, visualize, alert on, and explore your metrics. In conclusion, Prometheous scrapes and stores performance metrics and Grafana queries on this database, while visualizing the results in dashboards.

# Deployment Diagram 
In order to create a well-visualized result of our work, we created a deployment diagram following the rules in [this link](https://www.geeksforgeeks.org/system-design/deployment-diagram-unified-modeling-languageuml/) : 
<img width="1548" height="1021" alt="DeploymentDiagram" src="https://github.com/user-attachments/assets/354a4649-e811-4e4f-bbfc-25f2b9f6cf58" />

# Further Details 
### Netboot consequencies
- `hpc_master` and all the worker PIs boot from the network (Netboot) and their filesystem type is `nfs`. We used this command to see this: `hpc_master@ubuntu$ df -T $(which ping)`<br>We found that this changes the permissions of some files such as the ping executable and we now have to use `sudo ping <addr>`
- In order to be able to apt install packages in the hpc_master, the idea is to create a proxy between the hpc_master and the login node. In the latter node we install squid and there we sudo nano /etc/squid/squid.conf and add these two lines above the http_access deny all:
acl localnet src 192.168.2.117
http_access allow localnet
Then sudo systemctl restart squid in order the changes to be applied. In the file ~./bashrc we add at the end these
export http_proxy="http://192.168.2.1:3128"
export https_proxy="http://192.168.2.1:3128"
Lastly we create this /etc/apt/apt.conf and inside we add these two lines:<br>
Acquire::http::Proxy "http://192.168.2.1:3128"; <br>
Acquire::https::Proxy "http://192.168.2.1:3128";

### Apt problems
_ChatGPT session used to fix below issues: https://chatgpt.com/share/67e06d52-1ed4-8001-9511-8107e352d857_
- Every time we tried to install any package with apt we got messages like this: `/usr/bin/mandb: fopen /var/cache/man/zh_CN/42094: Permission denied` at the end of the output. **Fix**: changed permissions: `sudo chown -R root:man /var/cache/man` and `sudo chmod -R g+w /var/cache/man`
- `flash-kernel` package always failed so we removed it since with boot from the network and not from sd card `apt remove flash-kernel`
- There are still some issues with `initramfs-tools` package **unsolved**

 ### Upgrade - Problems
 The initial setup establishes a compressed code of Linux kernel of vmlinuz-6.8.0-1010-raspi. This was altered due to a **sudo apt upgrade** 
 in the login node and the softlinks changed to vmlinuz-6.8.0-1020-raspi which was not an executable file. This was detected by journalctl and  inspecting the log files. So in order to fix this issue we gave the necessary rigths so as to make the new compressed kernel code by the     
 command **sudo chmod 755 vmlinuz-6.8.0-1020-raspi**. Then we reboot the pis and the problem was fixed.
  ![image](https://github.com/user-attachments/assets/892ba1f3-a046-4e71-92a3-4560c0ab55a6)

  ### PSSH Installation and use
  For more info see the link https://www.cyberciti.biz/cloud-computing/how-to-use-pssh-parallel-ssh-program-on-linux-unix/. PSSH is responsible for parallel ssh-ing. In order to install it in the hpc_master we perform **sudo apt install pssh**. The next step is to generate ssh keys in order to public-private keys for passwordless ssh. This step is already done. First we create a text file called hosts file from which pssh read hosts names. The syntax is pretty simple. Each line in the host file are of the form [user@]host[:port] and can include blank lines and comments lines beginning with “#”. Following the tutorial we name this text file **~/.pssh_hosts_files**. Then we run **pssh -i -h ~/.pssh_hosts_files date** and then this **pssh -i -h ~/.pssh_hosts_files uptime**. A typical example of the use of pssh is this **pssh -h ~/.pssh_hosts_files -- sudo apt-get -y update**. Because  when running parallel-ssh -h .pssh_hosts_files -i date we face an error failure about the authenticity of the host so we change the format of the hosts file to just red1 red2 ... blue8. Also the file of the hosts is now named pssh_hosts in the home of hpc_master and in order to run the commands to all hosts execute **parallel-ssh -h pssh_hosts -x "-F .ssh/config" -i date**

  In order to avoid typing the above command over and over again we have created the `prun.sh` executable that takes a command as a parameter. We have also created a link `prun` with the command `ln -s /home/hpc_master/prun.sh /usr/bin/prun` to be able to run commands to all of the workers using `prun <command>`.
