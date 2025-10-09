# Parallel SSH - Script

## Overview
The main script in this directory, **prun**, provides a convenient way to execute commands in parallel across all compute nodes. It uses **parallel-ssh (pssh)** to send the same command to every node listed in the cluster’s host file.
This is useful for quickly checking if all nodes are up, reachable, and behaving as expected — for example, verifying system time synchronization, network connectivity, or filesystem consistency.

## File structure

* prun &rarr; Bash script wrapper for parallel-ssh
* pssh_hosts &rarr; List of hostnames or IPs of the compute nodes

## Usage
To run a command across all compute nodes:

```bash
./prun '<command>'
```
For example, to check if all nodes are online and responding:

```bash
./prun 'date'
```

Expected output:

```
[1] red1: Thu Oct  9 13:42:10 UTC 2025
[2] red2: Thu Oct  9 13:42:10 UTC 2025
...
[16] blue8: Thu Oct  9 13:42:10 UTC 2025
```

If any node is down or unreachable, its output will indicate an error such as `Connection refused` or `Timed out`.

## How it works
The script internally runs:

```
parallel-ssh -h /home/hpc_master/pssh_hosts -x "-F /home/hpc_master/.ssh/config" -i "$1"
```
* `-h` specifies the list of hosts to contact
* `-x` passes SSH options (in this case using a custom SSH config file)
* `-i` prints output from each host as it arrives
* `$1` is the command passed to the script (for example, `uptime`, `df -h`, etc.)

This setup assumes passwordless SSH (via keys) from the master node to all compute nodes, which we have setup.

## Example troubleshooting commands
You can use **prun** to quickly diagnose cluster-wide issues:

| Command                                          | Purpose                                                   |
| ------------------------------------------------ | --------------------------------------------------------- |
| ./prun 'date'                                    | Verify all nodes are up and their clocks are synchronized |
| ./prun 'uptime'                                  | Check system load and uptime across nodes                 |
| ./prun 'df -h /mnt/hpc_shared'                   | Check if shared storage (e.g. NFS mount) is accessible    |
| ./prun 'hostname'                                | Ensure each node reports its correct hostname             |
| ./prun 'top -bn1 | head -5'                      | Get a snapshot of CPU/memory usage                        |
| ./prun 'sudo systemctl status nfs-client.target' | Verify NFS client status across nodes                     |

## Prerequisites

* Make sure you have **parallel-ssh** installed:
  ```bash
  sudo apt install pssh
  ```
* Ensure SSH key-based authentication is correctly set up between the master node and all compute nodes.
* The file `/home/hpc_master/.ssh/config` should contain proper host definitions (HostName, User, IdentityFile, etc.) for all nodes.