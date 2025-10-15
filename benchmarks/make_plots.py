#!/usr/bin/env python3

import argparse
import matplotlib.pyplot as plt

CORES = [4, 8, 16, 32, 64]
BASIC_COMBINATIONS = ["4-1", "8-2", "16-4", "32-8", "64-16"]
LABELS = ["1-4", "2-8", "4-16", "8-32", "16-64"]

def __read_time(filename):
    try:
        with open(filename, 'r') as file:
            lines = file.readlines()
            for line in lines:
                if "Time in seconds" in line:
                    return float(line.split("=")[-1].strip())
    except FileNotFoundError:
        print(f"File {filename} not found!")
    
    return None

def __read_data(benchmark):
    data = {}
    for comb in BASIC_COMBINATIONS:
        parts = benchmark.split("-")
        filename = f"results/{parts[0]}/{parts[0]}-{parts[1]}-{comb}.out"
        time = __read_time(filename)
        if time: data[comb.split("-")[0]] = time
    
    return data

def __read_comparison_data(benchmarks, combinations):
    data = {}
    for b in benchmarks:
        data[b] = {}
        for c in combinations:
            filename = f"results/{b.split("-")[0]}/{b}-{c}.out"
            time = __read_time(filename)
            if time: data[b][f"{c.split("-")[1]}-{c.split("-")[0]}"] = time

    return data

def __basic_plot(x, Y, title, xlabel, ylabel, offsetX=1, offsetY=0, show=False, save=True, filename="plot.png"):
    def __find_label(val):
        for label in LABELS:
            if label.split("-")[1] == str(val):
                return label
        return str(val)
    
    plt.figure()
    plt.plot(x, Y, marker='o')
    plt.xticks(x)
    for i in range(len(x)):
        plt.text(x[i]+offsetX, Y[i]+offsetY, __find_label(x[i]), fontsize=8, ha='left', va='bottom')
    plt.xlabel(xlabel)
    plt.ylabel(ylabel)
    plt.title(title)
    plt.grid(True)
    if show: plt.show()
    if save: plt.savefig(f"plots/{filename}")

def make_comparison_plots(data, show=False, save=True):
    for benchmark in data.keys():
        b_data = data[benchmark]
        x = [int(k.split("-")[0]) for k in b_data.keys()]
        times = list(b_data.values())

        plt.figure()
        plt.grid(True)
        bars = plt.bar(x, times)

        for i, bar in enumerate(bars):
            height = bar.get_height()
            plt.text(
                bar.get_x() + bar.get_width() / 2,
                height,                              
                list(b_data.keys())[i],                         
                ha='center', va='bottom', fontsize=10, fontweight='bold'
            )

        plt.xticks(x)
        plt.title('Execution Time Comparison for '+benchmark)
        plt.xlabel("Number of Nodes")
        plt.ylabel("Execution Time (s)")
        
        if show: plt.show()
        if save: plt.savefig(f"plots/{benchmark}_comparison_plot.png")

def make_time_plot(benchmark, show=False, save=True):
    raw_data = __read_data(benchmark)
    data = list(raw_data.values())
    x = [int(k) for k in raw_data.keys()]

    __basic_plot(x, data,
                 title=f"Execution Time for {benchmark}",
                 xlabel="Number of Cores",
                 ylabel="Execution Time (s)",
                 show=show, save=save,
                 filename=f"{benchmark}_time_plot.png")

def make_speedup_plot(benchmark, show=False, save=True):
    raw_data = __read_data(benchmark)
    data = list(raw_data.values())
    x = [int(k) for k in raw_data.keys()]
    base_time = data[0]
    speedup = [base_time / t for t in data]

    __basic_plot(x, speedup,
                 title=f"Speedup for {benchmark}",
                 xlabel="Number of Cores",
                 ylabel="Speedup",
                 offsetY=-0.1,
                 show=show, save=save,
                 filename=f"{benchmark}_speedup_plot.png")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Generate plots for benchmark results.")
    parser.add_argument("--comp", action="store_true", help="Generate comparison plots")
    args = parser.parse_args()

    BENCHMARKS = ["is-D", "ep-D", "cg-C", "mg-C", "ft-C", "lu-D"]

    if args.comp:
        combinations = ["16-4", "16-8", "16-16"]
        make_comparison_plots(__read_comparison_data(BENCHMARKS, combinations), show=False, save=True)
    else:
        for b in BENCHMARKS:
            make_time_plot(b, show=False, save=True)
            make_speedup_plot(b, show=False, save=True)