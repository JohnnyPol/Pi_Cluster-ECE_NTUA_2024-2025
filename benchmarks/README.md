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

## Running the benchmarks

As described in the previous section, all benchmark binary files are located in the `/mnt/hpc_shared/NPB3.4.3/NPB3.4-MPI/bin/` directory. Each benchmark job is submitted to the cluster using Slurm's `sbatch` command. This was a command we used multiple times so we wrote a Python script, that you can find in `/benchmarks/scripts/job.py` directory of this repository, to automate this process. We have also created a bash alias to run this script with `job <benchmark> <pis> <cores>` from anywhere inside `hpc_master` node.
```bash
alias job='python3 /mnt/hpc_shared/job.py'
```

For example, if we want to run the class D of the `EP` benchmark on 8 worker nodes and 32 cores, we can simple type: 
```bash
job ep.D 8 32
```

This command is internally translated to:
```bash
sbatch --nodes=8 --ntasks=32 --wrap="srun --mpi=pmix /mnt/hpc_shared/NPB3.4.3/NPB3.4-MPI/bin/ep.D.x" -o ep-D-32-8.out -e ep-D-32-8.err
```

The job produces two output files in the directory where the command is executed:
- `ep-D-32-8.out` : standard output
- `ep-D-32-8.err` : standard error

## Results

In this section, we present the experiments we conducted and discuss any unexpected behaviors or anomalies observed during the runs. You can find all the output and error files in `/benchmarks/results`.

### Experiments Table

This table includes all the experiments that were used to create the resulting plots that you can find in the `/benchmarks/plots/` directory. The column names are formatted as follows: `<nodes>-<cores>`.

| Benchmark-Class | 1-4 | 2-8 | 4-16 | 8-16 | 16-16 | 8-32 | 16-64 |
|-----------|-----|-----|------|------|-------|------|-------|
| `IS-D` | ❌ | ❌ | ✔ | ✔ | ✔ | ✔ | ✔ |
| `EP-D` | ✔ | ✔ | ✔ | ✔ | ✔ | ✔ | ✔ |
| `CG-C` | ✔ | ✔ | ✔ | ✔ | ✔ | ✔ | ✔ |
| `MG-C` | ✔ | ✔ | ✔ | ✔ | ✔ | ✔ | ✔ |
| `FT-C` | ✔ | ✔ | ✔ | ✔ | ✔ | ✔ | ✔ |
| `LU-D` | ❌ | ✔ | ✔ | ✔ | ✔ | ✔ | ✔ |

The cases marked with ❌ were crashed with an `Out of memory` message and are not taken into account.

### Speedup Plots

We are going to present two speedup plots, one for `EP-D` and one for `FT-C`. The data processed to create each plot uses the experiments `1-4`, `2-8`, `4-16`, `8-32` and `16-64`. The formula used to extract the points is: 
```math
S_i = \frac{T_{1-4}}{T_i}
```
where $T_{1-4}$ is the execution time of the `1-4` experiment and $i$ can take `1-4`, `2-8`, `4-16`, `8-32` and `16-64`.

 **Embarrassingly Parallel(EP) class D speedup**
 
 ![ep-D-speedup](/benchmarks/plots/ep-D_speedup_plot.png)

 We can see that in this benchmark that there is little to no communication between the nodes, we get a near linear speedup. When we have x16 cores we get a speedup of $S \simeq 14$.

 **FFT(FT) class C speedup**

 ![ft-C-speedup](/benchmarks/plots/ft-C_speedup_plot.png)

 On the other hand, in the `FT` benchmark in which there is long-distance communication between nodes, we can clearly see that communication takes a big toll in our setup with a speedup of $S \simeq 6$ when we have x16 more cores.
