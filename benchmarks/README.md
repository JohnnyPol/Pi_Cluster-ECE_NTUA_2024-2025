# Benchmarking our SLURM HPC Raspberry Pi Cluster

We used the [NAS Parallel Benchmarks (NPB)](https://www.nas.nasa.gov/software/npb.html) suite to evaluate the performance and scalability of our cluster (1 master node: `hpc_master` + 16 worker nodes: `red[1-8]`, `blue[1-8]`). The goal is to observe how job execution time and speedup vary as we scale from a small number of nodes/tasks up to full cluster usage, and to identify any bottlenecks or deviations from ideal scaling.

---

## Benchmark suite description

The NAS Parallel Benchmarks (NPB) were developed by NASA Ames Research Center to assess the performance of parallel supercomputers. They consist of various kernel and pseudo-application benchmarks (such as IS, EP, CG, MG, FT, BT, SP, LU) designed to stress different aspects of parallel computation: integer sorting, communication‐intensive kernels, memory access, large all-to-all patterns, etc. Each benchmark is offered in different "classes" (S, W, A, B, C, D, E, F) that reflect increasing problem sizes. The table below summarizes the purpose of each benchmark and the corresponding problem class used in our tests.

| Benchmark | Description | Class |
|-----------|-------------|-------|
| `IS` | **Integer Sort**:  tests both integer computation speed and communication performance. | D |
| `EP` | **Embarrassingly Parallel**: tests the performance without significant interprocessor communication. | D |
| `CG` | **Conjugate Gradient**: tests irregular long distance communication. | C |
| `MG` | **MultiGrid**: tests both short and long distance data communication. | C |
| `FT` | **FFT**: tests long-distance communication performance. | C |
| `LU` | **LU Solver**: tests computational fluid dynamics workloads with nearest-neighbor communication and high memory usage. | D |

---

## Building the benchmarks

We downloaded the source code of the NPB and built (with MPI) the problem classes as seen in the table above.
1. Download (in the shared `/mnt/hpc_shared` directory) and un-tar the file
   ```bash
   wget https://www.nas.nasa.gov/assets/npb/NPB3.4.3.tar.gz
   tar -xvzf NPB3.4.3.tar.gz
   ```
2. Create the configuration file (we used the default one)
   ```bash
   cd /mnt/hpc_shared/NPB3.4.3/NPB3.4-MPI/config
   cp make.def.template make.def
   cd ..
   ```
3. Build the benchmarks. For example `EP` class D:
   ```bash
   make ep CLASS=D
   ```

The generated binary file will be inside the `bin` folder and have a name format `<benchmark>.<class>.x` (e.g. `ep.D.x`).
