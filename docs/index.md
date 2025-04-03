# HPC Cluster Documentation

Welcome to the documentation for our HPC cluster!

## Architecture Overview
- **Login Node**: Used for SSH access and launching jobs.
- **Compute Nodes**: Booted via network, no internet access.
- **HPC Master**: Manages SLURM, NIS, NFS, and automation.

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
  For more info see the link https://www.cyberciti.biz/cloud-computing/how-to-use-pssh-parallel-ssh-program-on-linux-unix/. PSSH is responsible for parallel ssh-ing. In order to install it in the hpc_master we perform **sudo apt install pssh**. The next step is to generate ssh keys in order to public-private keys for passwordless ssh. This step is already done. First we create a text file called hosts file from which pssh read hosts names. The syntax is pretty simple. Each line in the host file are of the form [user@]host[:port] and can include blank lines and comments lines beginning with “#”. Following the tutorial we name this text file **~/.pssh_hosts_files**. Then we run **pssh -i -h ~/.pssh_hosts_files date** and then this **pssh -i -h ~/.pssh_hosts_files uptime**. A typical example of the use of pssh is this **pssh -h ~/.pssh_hosts_files -- sudo apt-get -y update**



 
