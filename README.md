# HPC_Cluster-ECE_NTUA_2024-2025  

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
1. [Overview](#overview)
2. [System Architecture](#system-architecture)
3. [Network Infrastructure](#network-infrastructure)
4. [Cluster Components](#cluster-components)
5. [Performance Evaluation](#performance-evaluation)
6. [Troubleshooting](#troubleshooting)
7. [Contributors](#contributors)
8. [Acknowledgements](#acknowledgements)
9. [References](#references)

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

**Operating System:** Ubuntu 24.04 
**Networking:** Static IP configuration over Gigabit Ethernet  
**Boot Method:** PXE (diskless network boot)  
**Storage:** NFS shared filesystem  
**User Management:** Centralized with NIS  
**Job Scheduling:** SLURM + Munge + MariaDB + MPI  
**Monitoring:** Prometheus + Grafana + Node Exporter

### Diagram
![HPC Architecture](https://github.com/user-attachments/assets/9f6bae73-c693-498a-b627-d2d508630565)

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

## Automation
ANSIBLE
All scripts are in the corresponding folder


---


## Troubleshooting  

All known issues, diagnostic steps, and recovery procedures are centralized in a dedicated guide covering PXE, NFS, NIS, SLURM, and monitoring components.  

[Read the Troubleshooting Guide](./Troubleshooting/README.md)

---

## Contributors
* [Nikolas Spyropoulos](https://github.com/nspyrop03)
* [Giannis Polychronopoulos](https://github.com/JohnnyPol)
* [Nikolaos Tsalkitzis](https://github.com/nikostsalkitzis)
* [Nikolaos Mpeligiannis](https://github.com/nikolaosss)
* [George Kouseris](https://en.wikipedia.org/wiki/I_Don%27t_Know)

---
## Acknowledgements  
This project was developed by students of **ECE, NTUA (2024–2025)** within the framework of **Parallel Processing Systems and HPC research**.  

Special thanks to:
- CSLab, NTUA, for technical guidance  
- Raspberry Pi Foundation for the open hardware platform  
- The open-source communities of SLURM, Ansible, and Prometheus  

## References
> You may find these links useful <br>
[Git Repository Similar Project](https://github.com/projectRaspberry/wipi) <br>
[Article for Slurm](https://www.howtoraspberry.com/2022/03/how-to-build-an-hpc-high-performance-cluster-with-raspberry-pi-computers/) <br>
[Another Article for Slurm ](https://medium.com/@hghcomphys/building-slurm-hpc-cluster-with-raspberry-pis-step-by-step-guide-ae84a58692d5)<br>
[PDF of HPC Cluster Documentation](https://wr.informatik.uni-hamburg.de/_media/teaching/sommersemester_2021/ps-21_rasperry-pi-cluster.pdf) <br>
[PDF Slides (Probably not Useful)](https://archive.fosdem.org/2020/schedule/event/rpi_cluster/attachments/slides/3635/export/events/attachments/rpi_cluster/slides/3635/Introducing_HPC_with_a_Raspberry_Pi_Cluster.pdf) <br> 
[Article for NFS](https://www.howtoraspberry.com/2020/10/how-to-make-network-shared-storage-with-a-raspberry/) <br>
[Article for the Cluster Setup](https://jackyko1991.github.io/journal/Cluster-Setup-2.html) <br>
[Another Article for Cluster](https://glmdev.medium.com/building-a-raspberry-pi-cluster-784f0df9afbd) <br>
[Slurm Documentation](https://slurm.schedmd.com/documentation.html) <br>
[Useful YouTube Video for Slurm](https://www.youtube.com/watch?v=YZbRnrfECfo) <br>
[Slurm Installation Repository Tutorial](https://github.com/ReverseSage/Slurm-ubuntu-20.04.1) <br>
[Slurm Configuration Generator Tool](https://slurm.schedmd.com/configurator.html) <br>
