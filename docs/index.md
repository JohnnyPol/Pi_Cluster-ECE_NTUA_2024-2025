# HPC Cluster Documentation

Welcome to the documentation for our HPC cluster!

## Architecture Overview
- **Login Node**: Used for SSH access and launching jobs.
- **Compute Nodes**: Booted via network, no internet access.
- **HPC Master**: Manages SLURM, NIS, NFS, and automation.

### Netboot consequencies
- `hpc_master` and all the worker PIs boot from the network (Netboot) and their filesystem type is `nfs`. We used this command to see this: `hpc_master@ubuntu$ df -T $(which ping)`<br>We found that this changes the permissions of some files such as the ping executable and we now have to use `sudo ping <addr>`
