# Pi_Cluster-ECE_NTUA_2024-2025  

## Description  
This repository documents the full setup, configuration, and automation of an **HPC (High Performance Computing) cluster** built using **Raspberry Pi boards** by students of the **School of Electrical and Computer Engineering, NTUA (2024–2025)**.  

The project’s primary goal is to **design a scalable, educational, and fully functional HPC environment** using low-cost hardware. The cluster supports:
- **Centralized user and resource management** (via NIS, NFS, SLURM)
- **Automated provisioning** and configuration (via Ansible)
- **Network booting** for stateless worker nodes (via PXE)
- **Real-time monitoring and visualization** (via Prometheus + Grafana)

The repository is modular: each subsystem has its own configuration and detailed guide within a dedicated folder.

---

## Architecture  
Our team has developed a high-performance computing (HPC) cluster using 18 Raspberry Pi 4 devices. The cluster is composed of:

- **16 worker nodes (clients)**
- **1 master node**
- **1 login node**

The worker nodes are splitted in two different teams(each one of 8 pis) with names red and blue.

**Key characteristics:**
- **OS:** Raspberry Pi OS (64-bit, Lite)
- **Networking:** Static IP addressing, SSH communication  
- **Boot method:** PXE over Ethernet (diskless workers)  
- **Shared storage:** NFS mounted home and shared directories  
- **User management:** Centralized via NIS  
- **Job scheduling:** SLURM with Munge authentication and MPI integration  
- **Monitoring:** Prometheus, Node Exporter, and Grafana dashboard  

### Login Node Setup
How we download the OS for the login node and the other nodes. 
Step by step how we setup the login node
Write a script for this.
---

## Netboot (PXE Boot)  
Worker nodes are configured to boot entirely from the network using **PXE (Preboot Execution Environment)**.  
This allows **diskless booting**, centralized system updates, and simplified node management.  

[See detailed setup](./PXE/README.md)

---

## NFS  
The **Network File System (NFS)** provides a shared filesystem across all nodes.  
It enables users to access the same home directories, binaries, and datasets from any node, ensuring a consistent environment.  

[See detailed setup](./NFS/README.md)

---

## NIS  
The **Network Information Service (NIS)** offers centralized authentication and user management.  
Users defined on the master node can log into any worker node seamlessly, maintaining unified credentials and permissions.  

[See detailed setup](./NIS/README.md)

---

## SLURM  
**SLURM (Simple Linux Utility for Resource Management)** handles job scheduling and workload management across the cluster.  
It integrates with:
- **Munge** for node authentication  
- **MariaDB** for job accounting  
- **MPI** for distributed parallel processing  

[See detailed setup](./SLURM/README.md)

---

## Grafana / Prometheus & Node Exporters  
The monitoring stack collects and visualizes metrics from all nodes.  
- **Prometheus**: scrapes metrics from Node Exporters  
- **Node Exporters**: report CPU, memory, network, and disk statistics  
- **Grafana**: provides dashboards and visualization panels for real-time monitoring and alerting  

[See detailed setup](./Monitoring/README.md)

---

## NAS Benchmarks  
This section is reserved for **future benchmarking and performance evaluation** of the shared network storage (NFS/NAS).  
Tests will include throughput, latency, and scalability metrics under different workloads.

---

## Troubleshooting  
Common issues, log references, and recovery steps are collected in a dedicated troubleshooting guide covering all subsystems (PXE, NFS, NIS, SLURM, Monitoring).  

[See troubleshooting guide](./Troubleshooting/README.md)

---

