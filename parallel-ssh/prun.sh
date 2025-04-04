#!/bin/bash

# Check if a command is provided
if [ $# -eq 0 ]; then
    echo "Usage: $0 '<command>'"
    exit 1
fi

# Run parallel-ssh with the provided command
parallel-ssh -h /home/hpc_master/pssh_hosts -x "-F /home/hpc_master/.ssh/config" -i "$1"

