# HPC Team Documentation
- [Main Target and Structure of Pi's Cluster](#main-target-and-structure-of-pis-cluster)
- [Features](#features)

---
# Main Target and Structure of the Pi Cluster

Our team has developed a high-performance computing (HPC) cluster using 16 Raspberry Pi 4 devices. The cluster is composed of:

- **14 worker nodes (clients)**
- **1 master node**
- **1 login node**

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

