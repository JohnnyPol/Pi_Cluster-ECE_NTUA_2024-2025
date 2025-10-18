# HPC SLURM Raspberry Pi Cluster

This document describes the setup and configuration of our High-Performance Computing (HPC) cluster built with Raspberry Pis. The cluster uses **SLURM** (Simple Linux Utility for Resource Management) as its workload manager, **Munge** for authentication, and **MariaDB** for job accounting and tracking.

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

## TO-DO: Setup Guide + Config changes + Ansible scripts

## Setup Guide

Here we document the steps we followed to set up Slurm, based primarily on [this guide](https://github.com/ReverseSage/Slurm-ubuntu-20.04.1) as well as on various community forum discussions. During the Slurm setup, we developed several Ansible and Bash automation scripts to speed up the process. We recommend reading these scripts alongside this guide to better understand each configuration step.

### Steps Overview
1. Cluster time synchronization (chrony)
2. Common users and groups (NIS)
3. Common directory (NFS)
4. Munge, Slurm and MariaDB installation

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

The following table depicts the UIDs and GIDs chosen for the new user and groups:
| User/Group | UID | GID |
|------------|-----|-----|
| `slurm` | 1121 | 1121 |
| `munge` | 1111 | 1111 |

---

### 3. Common directory

All the nodes must be able to write to and read from shared files. To achieve this, we set up a common directory accessible to all nodes at `/mnt/hpc_shared`. Please refer to our [NFS setup guide](/NFS/README.md) for instructions on configuring your own NFS shared directory.

