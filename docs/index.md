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
Lastly we create this /etc/apt/apt.conf and inside we add these two lines
Acquire::http::Proxy "http://192.168.2.1:3128";
Acquire::https::Proxy "http://192.168.2.1:3128";


 
  
