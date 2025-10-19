# HPC SLURM Raspberry Pi Cluster

This document describes the setup and configuration of our High-Performance Computing (HPC) cluster built with Raspberry Pis. The cluster uses **SLURM** (Simple Linux Utility for Resource Management) as its workload manager, **Munge** for authentication, and **MariaDB** for job accounting and tracking.

---

## Table of Contents

- [HPC SLURM Raspberry Pi Cluster](#hpc-slurm-raspberry-pi-cluster)
  - [Table of Contents](#table-of-contents)
  - [Cluster Architecture](#cluster-architecture)
  - [What is Slurm?](#what-is-slurm)
    - [Key Components](#key-components)
  - [How does Slurm work?](#how-does-slurm-work)
    - [Integration with MPI](#integration-with-mpi)
  - [Munge Authentication](#munge-authentication)
    - [How does Munge Work?](#how-does-munge-work)
  - [Job Accounting with MariaDB](#job-accounting-with-mariadb)
    - [Components](#components)
  - [Setup Guide](#setup-guide)
    - [Steps Overview](#steps-overview)
    - [1. Cluster time synchronization](#1-cluster-time-synchronization)
    - [2. Common users and groups](#2-common-users-and-groups)
    - [3. Common directory](#3-common-directory)
    - [4. Munge installation](#4-munge-installation)
    - [5. MariaDB installation](#5-mariadb-installation)
    - [6. Slurm installation](#6-slurm-installation)
  - [Troubleshooting](#troubleshooting)

---

## Cluster Architecture

| Role | Hostname | Description |
|------|-----------|-------------|
| Master Node | `hpc_master` | Central management node running Slurm controller (`slurmctld`), MariaDB, and Munge daemon |
| Worker Nodes | `red[1-8]`, `blue[1-8]` | Compute nodes running Slurm daemon (`slurmd`) and Munge daemon |

- Total nodes: 17 (1 master + 16 workers)
- All nodes are connected over a private network and share a common `/mnt/hpc_shared` directory using [NFS](/NFS/README.md).

---

## What is Slurm?

[Slurm](https://slurm.schedmd.com/documentation.html) (Simple Linux Utility for Resource Management) is an open-source workload manager designed for Linux clusters. It is responsible for:

- Allocating resources (CPUs, memory, nodes) to jobs  
- Scheduling and queuing job execution  
- Managing job dependencies and priorities  
- Monitoring job and node states

### Key Components

| Component | Description |
|------------|-------------|
| `slurmctld` | The central **controller daemon** that manages the cluster and scheduling decisions (runs on `hpc_master`) |
| `slurmd` | The **compute node daemon** that executes and monitors jobs (runs on each worker) |
| `slurmdbd` | Optional **database daemon** for accounting (runs on `hpc_master`, connected to MariaDB) |
| `sacct` / `squeue` | User tools to query job/accounting info |

---

## How does Slurm work?

1. **User submits a job** using `sbatch` (batch) or `srun` (interactive).  
2. The job request goes to `slurmctld` on the master node.  
3. `slurmctld` checks available resources and schedules the job.  
4. The selected worker node's `slurmd` executes the job.  
5. Job information is logged and optionally stored in MariaDB for accounting.

### Integration with MPI

Slurm integrates seamlessly with **MPI (Message Passing Interface)**, allowing users to run distributed parallel applications across multiple nodes. When an MPI job is submitted, Slurm manages both the **resource allocation** and **process launching**, ensuring that each MPI rank is correctly mapped to the assigned CPUs and nodes.
Let's see step by step how it is done:

1. **Resource Allocation**: The user specifies the number of nodes and tasks required, for example:
   ```bash
   srun -N 4 -n 16 --mpi=pmix ./mpi_program
   ```
   Slurm reserves 4 nodes(workers) and launches 16 tasks accross them.
2. **MPI Environment Setup**: Slurm exports environment variables (such as `SLURM_NODELIST`, `SLURM_NTASKS`, `SLURM_PROCID`, etc.) that MPI uses to establish interprocess communication.
3. **Process Launching**: Slurm directly launches the tasks and performs initialization of communications through the PMIx API.
4. **Communication**: MPI uses the cluster's network for inter-node communication. Slurm ensures that only authorized nodes within the job allocation can communicate, maintaining both efficiency and isolation.
---

## Munge Authentication

[Munge (MUNGE Uid 'N' Gid Emporium)](https://dun.github.io/munge/) provides a simple, secure authentication mechanism for Slurm. It creates and validates credentials using a shared secret key, enabling trusted communication between cluster nodes without relying on network encryption.

### How does Munge Work?

1. All nodes share the same **key file** (e.g., `/etc/munge/munge.key`).  
2. Munge daemons (`munged`) run on every node.  
3. When a user or process authenticates, Munge encodes the user's UID/GID and a timestamp into a credential.  
4. The credential is validated by the target node's `munged` service, ensuring the request originates from a trusted node.

---

## Job Accounting with MariaDB

Slurm uses [MariaDB](https://mariadb.org/) for persistent job accounting and historical tracking via the Slurm Database Daemon (`slurmdbd`).

### Components

| Component | Function |
|-----------|----------|
| `slurmdbd` | Connects Slurm to MariaDB and handles accounting data |
| `slurmctld` | Reports job data to `slurmdbd` |
| `MariaDB` | Stores job records (start time, end time, resources used, user, exit codes, etc.) |

---

## Setup Guide

Here we document the steps we followed to set up Slurm, based primarily on [this guide](https://github.com/ReverseSage/Slurm-ubuntu-20.04.1) as well as on various community forum discussions. During the Slurm setup, we developed several Ansible and Bash automation scripts to speed up the process. We recommend reading these scripts alongside this guide to better understand each configuration step.

### Steps Overview
1. Cluster time synchronization (chrony)
2. Common users and groups (NIS)
3. Common directory (NFS)
4. Munge installation
5. MariaDB installation
6. Slurm installation

---

### 1. Cluster time synchronization

Both the master and the workers need to be synchronized. In order to do that we are going to use [chrony](https://chrony-project.org/). Chrony is an implementation of the **Network Time Protocol(NTP)** and can be used to synchronize the machine's clock with the NTP servers specified. We are going to synchronize the `hpc_master` node with the UTC time and every worker node will be set to have the same time as the master node. Here is how we can do that:

1. Install `chrony` on every node (both master and workers):
   ```bash
   sudo apt update
   sudo apt install chrony
   ```
2. Edit chrony's configuration file `/etc/chrony/chrony.conf` as mentioned above:

   In the `hpc_master`'s config file we are going to add these lines:
   ```bash
   allow 192.168.2.0/24

   # Default Ubuntu NTP servers are okay
   server ntp.ubuntu.com iburst

   local stratum 10
   ```

   In the worker nodes' config files, first comment out every line starting with `pool` or `server` and then add:
   ```bash
   # Use hpc_master Pi as NTP server
   server 192.168.2.117 iburst
   ```
   _Note_: `192.168.2.117` is the address of `hpc_master` in our local network
3. Restart and enable the `chrony` service first on `hpc_master` and then on all the workers:
   ```bash
   sudo systemctl restart chrony
   sudo systemctl enable chrony
   ```
4. Test if the setup was successful with `chronyc sources`:
   
   **Master node**:
   
   ![chronyc-master](/SLURM/images/chronyc_master.png)
   
   **Worker nodes**:
   
   ![chronyc-worker](/SLURM/images/chronyc_worker.png)

---

### 2. Common users and groups

Next, we have to create common `slurm` and `munge` users and groups in every node. This is required by slurm and munge to work properly. In addition to that, it is easier to handle file permissions when every node has the same users with the same user and group ids. We are using **NIS** to create common users and groups instead of just creating them by hand for every node so we can automate and better handle this task. You can find our NIS setup guide [here](/NIS/README.md).

The following table depicts the UIDs and GIDs chosen for the new users and groups:
| User/Group | UID | GID |
|------------|-----|-----|
| `slurm` | 1121 | 1121 |
| `munge` | 1111 | 1111 |

---

### 3. Common directory

All the nodes must be able to write to and read from shared files. To achieve this, we set up a common directory accessible to all nodes at `/mnt/hpc_shared`. Please refer to our [NFS setup guide](/NFS/README.md) for instructions on configuring your own NFS shared directory.

---

### 4. Munge installation

Munge is responsible for the authentication processes inside Slurm. First, we have to setup munge on `hpc_master` and generate a key that all nodes will share. After that, we install Munge on all worker nodes and copy the shared key in their local directories.

**Master node guide**:

1. Install Munge
   ```bash
   sudo apt install libmunge-dev libmunge2 munge -y
   sudo systemctl enable munge
   sudo systemctl start munge
    ```
2. Test the installation with `munge -n | unmunge | grep STATUS`. You should see a `Success (0)` status message
3. Copy the generated munge key into the shared directory and change the permissions so the worker nodes can get it:
   ```bash
   sudo cp /etc/munge/munge.key /mnt/hpc_shared/
   sudo chown munge /mnt/hpc_shared/munge.key
   sudo chmod 400 /mnt/hpc_shared/munge.key
   ```

**Worker nodes guide**

The Munge setup for workers is fully automated with the scripts that we have developed. You can find the scripts in the `SLURM/scripts` directory of this repositoty. You have to run only one script that installs Munge, its dependencies, copies the key from the shared directory to the local one and starts the service: `ansible-playbook setup_munge.yml`

**Extra scripts for specific tasks**

- `start_munge_service.yml` : enables and starts the Munge service
- `copy_munge_key.yml` : copies the key from the shared directory to the local one
- `check_munge_key.yml` : checks if the key is copied locally

--- 

### 5. MariaDB installation

MariaDB is needed by Slurm to keep details about submitted jobs. Let's set it up:

1. Install the `mariadb-server` package
   ```bash
   sudo apt install mariadb-server
   ```
2. Start the server and login
   ```bash
   sudo systemctl enable mysql
   sudo systemctl start mysql
   sudo mysql -u root
   ```
3. Create the account that Slurm will use
   ```bash
   create database slurm_acct_db;
   create user 'slurm'@'localhost';
   set password for 'slurm'@'localhost' = password('password');
   grant usage on *.* to 'slurm'@'localhost';
   grant all privileges on slurm_acct_db.* to 'slurm'@'localhost';
   flush privileges;
   exit
   ```
   _Note_: Change 'password' with your own unique and safe password

_Note_: We are going to modify the configuration file that Slurm uses to configure the database later in this guide.

---

### 6. Slurm installation

**Master Node**

1. Install slurm
   ```bash
   sudo apt install slurm-wlm slurm-wlm-basic-plugins
   ```
2. Create needed directories
   ```bash
   sudo mkdir -p /etc/slurm /etc/slurm/prolog.d /etc/slurm/epilog.d /var/spool/slurm/ctld /var/spool/slurm/d /var/log/slurm
   sudo chown slurm /var/spool/slurm/ctld /var/spool/slurm/d /var/log/slurm
   ```
3. Copy `/SLURM/config/slurm.conf` into `/etc/slurm/` and change the NodeNames at the end of the file
4. Copy `/SLURM/config/slurmdb.conf` into `/etc/slurm/` and go through the settings
5. Enable and start the services
   ```bash
   sudo systemctl daemon-reload
   sudo systemctl enable slurmdbd
   sudo systemctl start slurmdbd
   sudo systemctl enable slurmctld
   sudo systemctl start slurmctld
   ```

**Worker Nodes**

Once again, when it comes to the workers we have automated the setup with ansible scripts.

1. Install slurm packages
   ```bash
   ansible-playbook install_slurm.yml
   ```
2. Create slurm directories with correct permissions
   ```bash
   ansible-playbook create_slurm_dirs.yml
   ```
3. Copy the config files
   ```bash
   ansible-playbook copy_slurm_config.yml
   ansible-playbook copy_db_slurm_config.yml
   ```
4. Start the service
   ```bash
   ansible-playbook start_slurmd_service.yml
   ```

---

## Troubleshooting

The main issue we encountered was that, at random intervals, the `slurmd` service on some nodes would crash. When running `sinfo`, these nodes appeared with a status of `down*`. Restarting the `slurmd` service alone did not resolve the problem; a full reboot of the affected Raspberry Pi was required. To automate the recovery process, we created a simple bash function that resets the status of a failed node:

```bash
resetnode() {
  local node=$1
  if [ -z "$node" ]; then
    echo "Usage: resetnode <NodeName>"
    return 1
  fi
  sudo scontrol update NodeName=$node State=DOWN Reason="Resetting"
  sudo scontrol update NodeName=$node State=RESUME
}
```

With this function we can type `resetnode "red[1-8],blue[1-8]"` and the slurm controller will try to reset all nodes' status.
