# HPC_Pi_Cluster-ECE_NTUA_2024-2025  

![License](https://img.shields.io/badge/license-MIT-blue.svg)
![Raspberry Pi](https://img.shields.io/badge/hardware-Raspberry%20Pi%204-red.svg)
![Cluster Nodes](https://img.shields.io/badge/nodes-18-brightgreen.svg)
![OS](https://img.shields.io/badge/OS-Raspberry%20Pi%20OS%20Lite-ff69b4.svg)
![Automation](https://img.shields.io/badge/automation-Ansible-orange.svg)
![Monitoring](https://img.shields.io/badge/monitoring-Prometheus%20%26%20Grafana-yellow.svg)
![Scheduler](https://img.shields.io/badge/job%20scheduler-SLURM-blueviolet.svg)
![MPI](https://img.shields.io/badge/parallel-MPI-important.svg)
![Architecture](https://img.shields.io/badge/architecture-HPC%20Cluster-lightgrey.svg)
![Institution](https://img.shields.io/badge/NTUA-ECE-0057b8.svg)

---

## Table of Contents
- [HPC\_Pi\_Cluster-ECE\_NTUA\_2024-2025](#hpc_pi_cluster-ece_ntua_2024-2025)
  - [Table of Contents](#table-of-contents)
  - [Overview](#overview)
    - [Key Capabilities](#key-capabilities)
  - [System Architecture](#system-architecture)
    - [Diagram](#diagram)
  - [Network Infrastructure](#network-infrastructure)
  - [Cluster Components](#cluster-components)
  - [Performance Evaluation](#performance-evaluation)
  - [Troubleshooting](#troubleshooting)
  - [Acknowledgements](#acknowledgements)

---
## Overview  
**Pi_Cluster-ECE_NTUA_2024-2025** documents the full setup, configuration, and automation of a **High Performance Computing (HPC)** cluster built using **Raspberry Pi boards** by students of the **School of Electrical and Computer Engineering, NTUA (2024–2025)**.

The goal is to create a **scalable, educational, and fully functional HPC environment** using low-cost hardware.  
This environment enables research and learning in **parallel computing**, **distributed systems**, and **cluster automation**.

### Key Capabilities
- Centralized user and resource management (NIS + NFS)
- Automated provisioning via Ansible
- Stateless PXE network boot for worker nodes
- Job scheduling with SLURM and MPI integration
- Real-time performance monitoring with Prometheus & Grafana

---

## System Architecture  

The cluster consists of **18 Raspberry Pi 4** units:
- **1 Login Node** – User entry point, OS image management  
- **1 Master Node** – Orchestration, NFS, NIS, SLURM, Monitoring  
- **16 Worker Nodes** – Compute units divided into two groups:
  - `red1–red8`
  - `blue1–blue8`

**Operating System:** Raspberry Pi OS (64-bit Lite)  
**Networking:** Static IP configuration over Gigabit Ethernet  
**Boot Method:** PXE (diskless network boot)  
**Storage:** NFS shared filesystem  
**User Management:** Centralized with NIS  
**Job Scheduling:** SLURM + Munge + MariaDB + MPI  
**Monitoring:** Prometheus + Grafana + Node Exporter

### Diagram
![HPC Architecture](HPC_Deployment_Diagram.svg)

---

## Network Infrastructure  

The nodes are interconnected through a **Ubiquiti Managed Layer 2 Switch**, forming the high-speed backbone of the cluster.

| Specification | Details |
|----------------|----------|
| **Layer** | L2 Managed |
| **Switching Speed** | 88 Gbps |
| **Ports** | 48 × 1 Gbps Ethernet + 2 × SFP |
| **PoE Support** | 802.3af / 802.3at (PoE+) |
| **Rack Mountable** | Yes |
| **Purpose** | Provides Gigabit connectivity and PoE power for all nodes |

This switch ensures **stable communication**, **traffic prioritization**, and **remote management** across the entire HPC network.

---

## Cluster Components  

Each subsystem is modular and documented in a dedicated folder.

| Subsystem | Description | Documentation |
|------------|--------------|----------------|
| **PXE (Netboot)** | Enables diskless network boot for all worker nodes | [PXE Setup](./PXE/README.md) |
| **NFS** | Provides shared filesystem for home directories and datasets | [NFS Setup](./NFS/README.md) |
| **NIS** | Centralized user authentication and identity service | [NIS Setup](./NIS/README.md) |
| **SLURM** | Resource and job scheduler integrating MPI and Munge | [SLURM Setup](./SLURM/README.md) |
| **Monitoring** | Prometheus + Grafana + Node Exporter metrics stack | [Monitoring Setup](./Monitoring/README.md) |

## Performance Evaluation  

To assess performance and scalability, the cluster runs the **NAS Parallel Benchmarks (NPB)** suite from NASA.

These benchmarks measure:
- **Computation throughput** — overall processing speed across CPU cores.  
- **Inter-node communication performance** — network latency and bandwidth effects on distributed workloads (MPI).  
- **Scalability and parallel efficiency** — how execution time and speedup change as we increase nodes and cores.  
- **Resource and thermal behavior** — effects such as throttling or memory limits impacting sustained performance.

> Detailed results, plots, and interpretation are available in  
> [Benchmark Results Documentation](./benchmarks/README.md)

---

## Troubleshooting  

All known issues, diagnostic steps, and recovery procedures are centralized in a dedicated guide covering PXE, NFS, NIS, SLURM, and monitoring components.  

[Read the Troubleshooting Guide](./Troubleshooting/README.md)

---

## Acknowledgements  
This project was developed by students of **ECE, NTUA (2024–2025)** within the framework of **Parallel Processing Systems and HPC research**.  

Special thanks to:
- CSLab, NTUA for technical guidance  
- Raspberry Pi Foundation for the open hardware platform  
- The open-source communities of SLURM, Ansible, and Prometheus  