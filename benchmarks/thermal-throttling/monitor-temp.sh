#!/bin/bash
# Usage: ./monitor.sh <node>
# Logs Raspberry Pi CPU clock, temperature, and throttling to monitor-log-<node>.csv

# Check argument
if [ -z "$1" ]; then
  echo "Usage: $0 <node>"
  exit 1
fi

NODE="$1"
LOGFILE="monitor-log-${NODE}.csv"

echo "Logging to $LOGFILE..."
echo "time,clock_Hz,temp_C,throttled" > "$LOGFILE"

# Loop forever until stopped with Ctrl+C
while true; do
  t=$(date +"%T")
  clk=$(vcgencmd measure_clock arm | cut -d= -f2)
  temp=$(vcgencmd measure_temp | cut -d= -f2 | tr -d "'C")
  thr=$(vcgencmd get_throttled | cut -d= -f2)
  echo "$t,$clk,$temp,$thr" | tee -a "$LOGFILE"
  sleep 1
done

