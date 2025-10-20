#!/usr/bin/env python3

import pandas as pd
import matplotlib.pyplot as plt

TEMP_LIMIT = 80

# Function to plot one dataset
def plot_data(file, title, output_name):
    df = pd.read_csv(file)
    df["count"] = range(1, len(df) + 1)
    
    fig, ax1 = plt.subplots()
    ax2 = ax1.twinx()

    ax1.plot(df["count"], df["temp_C"], color="tab:red", label="Temperature (°C)")
    ax2.plot(df["count"], df["clock_Hz"], color="tab:blue", label="Clock (Hz)")

    ax1.set_xlabel("Seconds (s)")
    ax1.set_ylabel("Temperature (°C)", color="tab:red")
    ax2.set_ylabel("Clock Frequency (Hz)", color="tab:blue")
    ax1.tick_params(axis='y', labelcolor="tab:red")
    ax2.tick_params(axis='y', labelcolor="tab:blue")

    # Optional: show throttling limit
    if TEMP_LIMIT:
        ax1.axhline(TEMP_LIMIT, color="red", linestyle="--", label=f"Limit {TEMP_LIMIT}°C")

    fig.suptitle(title)
    fig.tight_layout()
    fig.savefig(f"plots/{output_name}.png")

if __name__ == "__main__":
    plot_data("monitor-log-red1-1.csv", "EP-D 8-32 red1 node statistics", "ep-D-32-8-red1")
    plot_data("monitor-log-blue2-1.csv", "EP-D 8-32 blue2 node statistics", "ep-D-32-8-blue2")
