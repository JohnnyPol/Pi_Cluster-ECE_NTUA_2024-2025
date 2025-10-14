import matplotlib.pyplot as plt

CORES = [4, 8, 16, 32, 64]
BASIC_COMBINATIONS = ["4-1", "8-2", "16-4", "32-8", "64-16"]
LABELS = ["1-4", "2-8", "4-16", "8-32", "16-64"]

def __read_data(benchmark):
    data = {}
    for comb in BASIC_COMBINATIONS:
        parts = benchmark.split("-")
        filename = f"results/{parts[0]}/{parts[0]}-{parts[1]}-{comb}.out"
        try:
            with open(filename, 'r') as file:
                lines = file.readlines()
                for line in lines:
                    if "Time in seconds" in line:
                        time = float(line.split("=")[-1].strip())
                        data[comb.split("-")[0]] = time
        except FileNotFoundError:
            print(f"File {filename} not found!")
            continue
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
    BENCHMARKS = ["is-D", "ep-D", "cg-C", "mg-C", "ft-C", "lu-D"]
    for b in BENCHMARKS:
        make_time_plot(b, show=False, save=True)
        make_speedup_plot(b, show=False, save=True)