# NIS Server/Client Setup Guide for HPC Cluster

This guide describes how to set up a **Network Information Service (NIS)** in a Linux-based HPC (High Performance Computing) cluster built with Raspberry Pis.
It explains **why NIS is required**, how to **configure both server and clients**, and provides **brief reasoning for each step** of the installation.

- [NIS Server/Client Setup Guide for HPC Cluster](#nis-serverclient-setup-guide-for-hpc-cluster)
  - [Why We Use NIS in Our HPC Cluster](#why-we-use-nis-in-our-hpc-cluster)
  - [Step-by-step Setup](#step-by-step-setup)
    - [**Step 1: Install Required Packages**](#step-1-install-required-packages)
    - [**Step 2: Set the NIS Domain Name**](#step-2-set-the-nis-domain-name)
    - [**Step 3: Configure `/etc/yp.conf` on Clients**](#step-3-configure-etcypconf-on-clients)
    - [**Step 4: Allow RPC Access**](#step-4-allow-rpc-access)
    - [**Step 5: Fix `_rpc` Missing User (if needed)**](#step-5-fix-_rpc-missing-user-if-needed)
    - [**Step 6: Enable NIS Maps on the Server**](#step-6-enable-nis-maps-on-the-server)
    - [**Step 7: Create a Shared User on the Server**](#step-7-create-a-shared-user-on-the-server)
    - [**Step 8: Modify `/etc/nsswitch.conf` on Clients**](#step-8-modify-etcnsswitchconf-on-clients)
    - [**Step 9: Allow NIS Lookups (Compatibility)**](#step-9-allow-nis-lookups-compatibility)
    - [**Step 10: (Optional) Enable Password-less sudo for Shared User**](#step-10-optional-enable-password-less-sudo-for-shared-user)
    - [**Step 11: Final Checks**](#step-11-final-checks)
    - [**Step 12: Maintenance and Firewall Notes**](#step-12-maintenance-and-firewall-notes)
  - [Automation with Ansible Scripts (NIS Server \& Clients)](#automation-with-ansible-scripts-nis-server--clients)


---

## Why We Use NIS in Our HPC Cluster

In an HPC cluster managed by **Slurm**, we have multiple nodes (login, hpc_master, and compute nodes).
All nodes must **recognize the same users and groups** — otherwise, jobs submitted by a user on the login node won’t run correctly on compute nodes, because the UID/GID won’t match.

NIS solves this by acting as a **centralized user directory**:

* The **NIS server** stores all user and group information (`/etc/passwd`, `/etc/group`, `/etc/shadow`).
* All **NIS clients** (compute nodes) automatically fetch that data when users log in or when Slurm runs a job.
* Thus, **UIDs and GIDs are consistent** across the entire cluster — ensuring correct permissions and seamless execution under Slurm.

Without NIS, you’d need to manually synchronize `/etc/passwd` and `/etc/group` files across all nodes — which is inefficient and error-prone.

---

## Step-by-step Setup

---

### **Step 1: Install Required Packages**

Install `rpcbind` for **RPC communication** and `nis` (NIS service tools) on both the server and all clients.

**What is RPC communication?**
RPC stands for **Remote Procedure Call**.
It’s a protocol that allows one machine to request a service or function execution on another machine — in this case, how NIS communicates between the server and clients.

```bash
sudo apt-get install rpcbind nis -y
```

---

### **Step 2: Set the NIS Domain Name**

Defines a logical **NIS domain name** that groups all machines into the same identity namespace.
All nodes in the cluster must share the same NIS domain name.
`/etc/defaultdomain` ensures that this name is remembered after reboot.

**What is a NIS domain name?**
It’s not related to DNS — it’s simply an internal label that identifies which NIS network a machine belongs to (like a cluster name).

```bash
sudo nisdomainname hpcnisdom
echo "hpcnisdom" | sudo tee /etc/defaultdomain
```

Excellent — here’s the **rewritten version of Steps 3 through the end**, perfectly matching the **style and logic flow** of Steps 1 and 2 (definition → why → commands).
Everything is consistent in tone, structure, and formatting.

---

### **Step 3: Configure `/etc/yp.conf` on Clients**
This file tells the client which **NIS domain** it belongs to and which **server** it should contact to obtain user and group information.

**What is `/etc/yp.conf`?**
It’s the main NIS client configuration file. It defines the NIS domain name and the address of the NIS server that provides the user databases.

```bash
echo "domain hpcnisdom server 192.168.2.117" | sudo tee -a /etc/yp.conf
echo "ypserver 192.168.2.117" | sudo tee -a /etc/yp.conf
```
Here we associate the domain `hpcnisdom` with the NIS server at IP `192.168.2.117`.
This allows each client node to know where to fetch the centralized user information from.

---

### **Step 4: Allow RPC Access**

NIS uses **RPC (Remote Procedure Call)** to communicate between the server and clients.
We must allow the `rpcbind` service (which manages RPC connections) to accept requests from cluster nodes.

```bash
echo "rpcbind: ALL" | sudo tee -a /etc/hosts.allow
```
This line ensures that RPC requests from all cluster nodes are permitted.
In a controlled cluster network, this is safe and necessary for NIS communication.

---

### **Step 5: Fix `_rpc` Missing User (if needed)**

Sometimes the `rpcbind` service fails to start because the system user `_rpc` is missing.

**Who is `_rpc`?**
It’s a system account used internally by the RPC subsystem — it has no login access and exists only so `rpcbind` can drop privileges securely.

If you see an error like:

```
rpcbind[358]: cannot get uid of "_rpc": Success
```

create the missing user and restart the services:

```bash
sudo useradd --system --no-create-home --shell /usr/sbin/nologin _rpc
sudo systemctl restart rpcbind
sudo systemctl restart ypbind
```
This creates the required system account and restarts the RPC services so that NIS can function normally.

---

### **Step 6: Enable NIS Maps on the Server**

On the NIS server, we must enable and initialize the database that holds all user and group information — called **NIS maps**.

**What are NIS maps?**
They are databases generated from files like `/etc/passwd`, `/etc/group`, and `/etc/shadow`, which store user and authentication data distributed to clients.

Edit the NIS configuration file and set the master mode:

```bash
sudo sed -i 's/^NISSERVER=.*$/NISSERVER=master/' /etc/default/nis
```

Then set the NIS domain and start the NIS service:

```bash
sudo nisdomainname hpcnisdom
sudo systemctl restart ypserv
```
This designates the server as the **master NIS host**, responsible for building and serving the user database to all clients in the `hpcnisdom` domain.

---

### **Step 7: Create a Shared User on the Server**

We’ll now create a user that all nodes will recognize through NIS.

**Why do this?**
Creating a shared account ensures that the same UID and GID exist across all machines.
Slurm requires consistent user IDs to schedule and execute jobs properly on compute nodes.

```bash
sudo useradd -m -u 1100 -s /bin/bash shareduser
sudo passwd shareduser
sudo usermod -aG sudo shareduser
```

After adding the user, rebuild the NIS maps so the clients see it:

```bash
sudo make -C /var/yp
```
This process adds the new account to the NIS databases and regenerates them under `/var/yp`, making the user available cluster-wide.

---

### **Step 8: Modify `/etc/nsswitch.conf` on Clients**

This file defines how the system looks up user and group information.
We add `nis` to instruct the system to check the NIS server in addition to local files.

**What is `nsswitch.conf`?**
It’s the **Name Service Switch** configuration file — it controls where the system looks for names and identities (local files, DNS, NIS, etc.).

```ini
passwd:         files nis
group:          files nis
shadow:         files nis

hosts:          files dns
networks:       files

protocols:      db files
services:       db files
ethers:         db files
rpc:            db files

netgroup:       nis
```
Now, when a user logs in, the system first checks local accounts, then consults NIS if the user isn’t found locally.

---

### **Step 9: Allow NIS Lookups (Compatibility)**

Some utilities require special lines in `/etc/passwd`, `/etc/group`, and `/etc/shadow` to merge local and NIS users.

**What do these entries do?**
They tell the system to include all accounts defined in the NIS database after the local entries.

```bash
sudo echo '+::::::'   | sudo tee -a /etc/passwd
sudo echo '+:::'      | sudo tee -a /etc/group
sudo echo '+::::::::' | sudo tee -a /etc/shadow
```
These plus-sign entries enable compatibility with the NIS naming system, ensuring that NIS-managed users appear in system commands like `getent passwd`.

---

### **Step 10: (Optional) Enable Password-less sudo for Shared User**

If you want the shared user to execute administrative commands without entering a password, you can modify `/etc/sudoers`.

**Why might this be useful?**
In a small, secure HPC environment, this simplifies management and automation — for example, deploying scripts across nodes without user interaction.

```bash
echo "shareduser ALL=(ALL) NOPASSWD: ALL" | sudo tee -a /etc/sudoers
```
This grants `shareduser` full administrative rights without password prompts.
Use it only in trusted environments.

---

### **Step 11: Final Checks**

Finally, confirm that NIS is correctly configured and synchronized between server and clients.

**Check the current NIS domain:**

```bash
domainname
```

Expected output:

```
hpcnisdom
```

**Check which server the client is bound to:**

```bash
ypwhich
```

Expected output:

```
192.168.2.117
```

**Check available NIS users (on server):**

```bash
ypcat passwd
```
If all commands return the expected results, your NIS setup is complete and functioning correctly across the cluster.

---

### **Step 12: Maintenance and Firewall Notes**

Whenever you create, delete, or modify users on the NIS server, update the maps with:

```bash
sudo make -C /var/yp
```

If you’re using a firewall (e.g., UFW), ensure NIS and RPC ports are open or disable the firewall temporarily during setup:

```bash
sudo ufw disable
```
NIS depends on dynamically assigned ports via `rpcbind`.
If blocked by a firewall, clients won’t be able to communicate with the server.

## Automation with Ansible Scripts (NIS Server & Clients)

To simplify and standardize the configuration of all cluster nodes, the NIS setup can be fully automated using the Ansible playbook [**nis_client_setup.yml**](./nis_client_setup.yml).

This playbook installs the required packages, sets the NIS domain, configures all related files (`/etc/yp.conf`, `/etc/nsswitch.conf`, `/etc/defaultdomain`), creates necessary system users, and restarts services — all in one automated run across every client node.
