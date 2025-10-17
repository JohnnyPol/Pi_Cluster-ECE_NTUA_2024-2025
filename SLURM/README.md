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
