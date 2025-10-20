# Benchmarking our SLURM HPC Raspberry Pi Cluster

We used the [NAS Parallel Benchmarks (NPB)](https://www.nas.nasa.gov/software/npb.html) suite to evaluate the performance and scalability of our cluster (1 master node: `hpc_master` + 16 worker nodes: `red[1-8]`, `blue[1-8]`). The goal is to observe how job execution time and speedup vary as we scale from a small number of nodes/tasks up to full cluster usage, and to identify any bottlenecks or deviations from ideal scaling.

---

## Table of contents
- [Benchmark suite description](#benchmark-suite-description)
- [Building the benchmarks](#building-the-benchmarks)
- [Running the benchmarks](#running-the-benchmarks)
- [Results](#results)
  - [Experiments Table](#experiments-table)
  - [Speedup Plots](#speedup-plots)
  - [An Interesting Discovery](#an-interesting-discovery)

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

---

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

---

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

### An Interesting Discovery

As demonstrated above, communication overhead can significantly impact the cluster's performance. To validate this observation, we formulated the hypothesis that for a fixed number of total cores (e.g., 16), using fewer nodes should result in faster execution times due to reduced inter-node communication. To test this, we compared the execution times from the `4-16`, `8-16`, and `16-16` experiments and plotted the results. Let's see these comparison plots for `EP-D` and `FT-C` again.

![ep-d-comp](/benchmarks/plots/ep-D_comparison_plot.png)

![ft-c-comp](/benchmarks/plots/ft-C_comparison_plot.png)

For the `EP-D` comparison plot we can see that the execution times are almost the same as the benchmark does not require excesive communication between the nodes. **But** the `FT-C` plot disproves our hypothesis! The `16-16` execution time is by far smaller than `4-16`. How is that possible when we know that the bottleneck of our architecture design is the network? The answer is hidden in the [thermal control](https://www.raspberrypi.com/documentation/computers/raspberry-pi.html#frequency-management-and-thermal-control) section of Raspberry Pi's official documentation. When the raspberry pi is loaded with heavy workload and the temperature hits **80&deg;C**, then the CPU drops its frequency! This phenomenon is called **Thermal Throttling**.

After reading the Raspberry Pi's thermal control documentation, we decided to design an experiment to observer the thermal throttling phenomenon and prove that this is the reason of the weird behaviour of the `16-16` experiment. We selected nodes `red[1-4]` and `blue[1-4]`, ran the `EP-D` benchmark with the `8-32` format and monitored `red1`'s and `blue2`'s system temperature and clock frequency with the [monitor-temp.sh](/benchmarks/thermal-throttling/monitor-temp.sh) script. The script uses the [vcgencmd](https://elinux.org/RPI_vcgencmd_usage) command. We plotted the results:

**Red1 node**:

![red1-thermal](/benchmarks/thermal-throttling/plots/ep-D-32-8-red1.png)

**Blue2 node**:

![blue2-thermal](/benchmarks/thermal-throttling/plots/ep-D-32-8-blue2.png)

We can clearly see the thermal throttling event occuring in the `blue2` plot. When the temperature is above **80&deg;C**, the clock frequency drops, sometimes even to 1/3 of the full speed(1.8GHz). We can also see that there is no thermal throttling in the `red1` plot. This is due to the node's position in the cluster(upper-left corner). It is not surounded by other working nodes.
