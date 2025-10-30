# Raspberry Pi Power-Cycle Script

## Overview

This Bash script allows administrators to **power cycle (restart)** selected Raspberry Pi nodes in the HPC cluster directly from the **login node**.
It interfaces with the **managed PoE network switch** (via SSH) to toggle power on the corresponding switch ports.

Instead of remembering port IDs or issuing raw switch commands, users can restart any Pi by name — e.g., `red4`, `blue7`, or an entire color group.

---

## Functionality

* **Single Pi restart:** Restart an individual node by name (e.g., `red3`).
* **Group restart:** Restart all `red` or all `blue` nodes.
* **Full cluster restart:** Restart all compute nodes (`all`), excluding `hpc_master`.
* **Confirmation prompt:** Prevents accidental reboots.
* **Mapping:** Node names are mapped to switch port IDs automatically.

---

## Usage

### 1. Make the script executable

```bash
chmod +x power_cycle.sh
```

### 2. Run the script with a target name

```bash
./power_cycle.sh <target>
```

### 3. Examples

```bash
./power_cycle.sh red1      # Restart red1
./power_cycle.sh blue6     # Restart blue6
./power_cycle.sh red       # Restart all red Pis
./power_cycle.sh blue      # Restart all blue Pis
./power_cycle.sh all       # Restart all compute nodes (excluding hpc_master)
```

You’ll be asked to confirm before any restart occurs:

```
Are you sure you want to restart red3? (y/n)
```

---

## How It Works

* Each Pi name (e.g., `red5`) is mapped to a **PoE port ID** on the switch.
* The script uses:

  ```bash
  sshpass -p '<password>' ssh ubnt@192.168.2.254 "swctrl poe restart id <PORT_ID>"
  ```

  to send a restart command via SSH to the managed switch (IP `192.168.2.254`).
* Ports are spaced evenly (red nodes on IDs 18–32, blue on 2–16, master on 13).

---

## Notes

* **Run from the login node only.**
* Requires:

  * `sshpass` installed (`sudo apt install sshpass`)
  * SSH access to the switch (`ubnt@192.168.2.254`)
* Do **not** run multiple simultaneous reboots — the script waits and sleeps between restarts for safety.
* The password is currently stored inline for convenience; for production use, consider migrating to key-based authentication.

---

## Output Example

```
$ ./power_cycle.sh blue3
Are you sure you want to restart blue3? (y/n) y
Restarting blue3 (6)
```
