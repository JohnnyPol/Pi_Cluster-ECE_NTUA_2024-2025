#!/bin/bash

# SSH Configuration for Compute Nodes
# -----------------------------------
# This SSH config file allows simplified SSH access to the compute nodes (red1-8, blue1-8) in the HPC cluster. 
# Instead of specifying full IP addresses and usernames, users can connect using:
#
#   ssh red1   (instead of ssh red1@192.168.2.101)
#   ssh blue3  (instead of ssh blue3@192.168.2.111)
#
# Configuration Details:
# - Each compute node has an alias (Host red1, Host blue1, etc.).
# - The corresponding IP address is mapped under `HostName`.
# - The default SSH username for each node is explicitly set under `User`.
# - The private key (`id_rsa`) is used for authentication.
#
# This configuration simplifies SSH connections and enables passwordless authentication 
# when SSH keys are properly set up.

# Define the worker nodes (red1-8, blue1-8)
NODES=(red1 red2 red3 red4 red5 red6 red7 red8 blue1 blue2 blue3 blue4 blue5 blue6 blue7 blue8)

# Copy SSH key to each node
for NODE in "${NODES[@]}"; do
    echo "Copying SSH key to $NODE..."
    ssh-copy-id -o "PasswordAuthentication yes" $NODE
done

echo "SSH key distribution complete!"
