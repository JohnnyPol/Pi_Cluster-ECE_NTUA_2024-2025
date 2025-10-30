# SSH Key Distribution Script for HPC Compute Nodes

## Overview

This script automates the setup of **passwordless SSH access** across all compute nodes in an HPC cluster.
It copies the master node’s public SSH key to each compute node (red1–red8 and blue1–blue8), enabling simple and secure connections using short hostnames like `ssh red3` instead of full addresses.

## Features

* Automatically distributes SSH keys to all defined nodes
* Simplifies SSH access via predefined host aliases
* Enables passwordless authentication (after initial setup)
* Works with both red and blue node groups

## Usage

1. Ensure your `~/.ssh/config` file contains entries for each node, e.g.:

   ```
   Host red1
       HostName 192.168.2.101
       User red1
       IdentityFile ~/.ssh/id_rsa
   ```
2. Make the script executable:

   ```bash
   chmod +x distribute_ssh_keys.sh
   ```
3. Run the script from the master node:

   ```bash
   ./distribute_ssh_keys.sh
   ```

During the first run, you will be prompted for each node’s password. After completion, SSH access will be passwordless.

## Output

* Displays progress messages while copying keys
* Prints **“SSH key distribution complete!”** when all nodes are configured

## Notes

* Ensure that SSH access is enabled and reachable for all nodes.
* Requires `ssh-copy-id` to be installed on the master node.
