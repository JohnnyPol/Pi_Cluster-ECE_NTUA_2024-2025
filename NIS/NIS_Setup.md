# 🔧 NIS Server/Client Setup Guide for HPC Cluster

This guide describes how to set up a **Network Information Service (NIS)** in a Linux-based HPC (High Performance Computing) cluster built with Raspberry Pis.
It explains **why NIS is required**, how to **configure both server and clients**, and provides **brief reasoning for each step** of the installation.

---

## 🧭 Why We Use NIS in Our HPC Cluster

In an HPC cluster managed by **Slurm**, we have multiple nodes (login, hpc_master, and compute nodes).
All nodes must **recognize the same users and groups** — otherwise, jobs submitted by a user on the login node won’t run correctly on compute nodes, because the UID/GID won’t match.

NIS solves this by acting as a **centralized user directory**:

* The **NIS server** stores all user and group information (`/etc/passwd`, `/etc/group`, `/etc/shadow`).
* All **NIS clients** (compute nodes) automatically fetch that data when users log in or when Slurm runs a job.
* Thus, **UIDs and GIDs are consistent** across the entire cluster — ensuring correct permissions and seamless execution under Slurm.

Without NIS, you’d need to manually synchronize `/etc/passwd` and `/etc/group` files across all nodes — which is inefficient and error-prone.

---

## ⚙️ Step-by-step Setup

---

### **Step 1: Install Required Packages**

**Command:**

```bash
sudo apt-get install rpcbind nis -y
```

**Explanation:**
Installs `rpcbind` (for RPC communication) and `nis` (NIS service tools) on both server and clients.
RPC (Remote Procedure Call) is required since NIS is built on RPC.

---

### **Step 2: Set the NIS Domain Name**

**Command:**

```bash
sudo nisdomainname hpcnisdom
echo "hpcnisdom" | sudo tee /etc/defaultdomain
```

**Explanation:**
Defines a logical **NIS domain name** (`hpcnisdom`) that groups all machines in the same identity namespace.
`/etc/defaultdomain` ensures this name persists across reboots.

---

### **Step 3: Configure `/etc/yp.conf`**

**Command (on Clients):**

```bash
echo "domain hpcnisdom server 192.168.2.117" | sudo tee -a /etc/yp.conf
echo "ypserver 192.168.2.117" | sudo tee -a /etc/yp.conf
```

**Explanation:**
Tells the client which NIS domain it belongs to and which machine (IP of the login/master node) is its **NIS server**.

---

### **Step 4: Allow RPC Access**

**Command:**

```bash
echo "rpcbind: ALL" | sudo tee -a /etc/hosts.allow
```

**Explanation:**
Ensures the `rpcbind` service accepts incoming connections from cluster nodes — required for NIS communication.

---

### **Step 5: Fix `_rpc` Missing User (If Needed)**

**Commands:**

```bash
sudo useradd --system --no-create-home --shell /usr/sbin/nologin _rpc
sudo systemctl restart rpcbind
sudo systemctl restart ypbind
```

**Explanation:**
Sometimes `rpcbind` fails if the `_rpc` system user is missing.
This creates it and restarts the related services to restore functionality.

---

### **Step 6: Enable NIS Maps on Server**

**Server Configuration:**

```bash
NISMASTER=YES
sudo nisdomainname hpcnisdom
sudo systemctl restart ypserv
```

**Explanation:**
Marks this node as the **master NIS server**, responsible for generating and distributing the NIS database ("maps") to clients.

---

### **Step 7: Create a Shared User**

**Server Command:**

```bash
sudo useradd -m -u 1100 -s /bin/bash shareduser
sudo passwd shareduser
sudo usermod -aG sudo shareduser
sudo make -C /var/yp
```

**Explanation:**
Creates a test user with a consistent UID (e.g., 1100) that will exist on all nodes through NIS.
After creation, the `make` command regenerates the NIS maps so clients see the new user.

---

### **Step 8: Modify `/etc/nsswitch.conf` (on Client)**

**Configuration Example:**

```ini
passwd:         files nis
group:          files nis
shadow:         files nis
```

**Explanation:**
Tells the system to check **local files first**, then **NIS** for user, group, and authentication data.
This integrates NIS into the system’s normal lookup mechanism.

---

### **Step 9: Allow NIS Lookups (Compatibility)**

**Command:**

```bash
sudo echo '+::::::'   | sudo tee -a /etc/passwd
sudo echo '+:::'      | sudo tee -a /etc/group
sudo echo '+::::::::' | sudo tee -a /etc/shadow
```

**Explanation:**
Allows NIS to append entries from the NIS maps into the system’s account database — a classic compatibility requirement for older NIS clients.

---

### **Step 10: (Optional) Password-less sudo for Shared User**

**Command:**

```bash
echo "shareduser ALL=(ALL) NOPASSWD: ALL" | sudo tee -a /etc/sudoers
```

**Explanation:**
Gives the shared user administrative access across nodes without entering a password — optional but convenient for cluster management/testing.

---

## ✅ Final Checks

1. **Confirm domain name:**

   ```bash
   domainname
   # → hpcnisdom
   ```
2. **Verify NIS binding:**

   ```bash
   ypwhich
   # → 192.168.2.117 (your NIS server)
   ```
3. **Check available users (on server):**

   ```bash
   ypcat passwd
   ```

---

## 🔄 Ongoing Maintenance

When you create or delete users on the NIS server, always run:

```bash
sudo make -C /var/yp
```

to rebuild and distribute the updated maps.

If you have a firewall enabled (UFW), ensure NIS and RPC ports are open — or disable UFW during setup:

```bash
sudo ufw disable
```

---

## 🧩 Summary

| Component             | Role                                   | Why It Matters                                           |
| --------------------- | -------------------------------------- | -------------------------------------------------------- |
| **NIS Server**        | Central database of users/groups       | Ensures consistent identity management across cluster    |
| **NIS Clients**       | Fetch user info from server            | Allows Slurm jobs to execute under correct user context  |
| **rpcbind**           | Handles NIS communication              | Required for NIS to function via RPC                     |
| **nsswitch.conf**     | Integrates NIS into system lookups     | Enables transparent authentication via NIS               |
| **Slurm Integration** | Uses same UID/GID mapping on all nodes | Prevents permission mismatches and job submission errors |

---

Would you like me to add a **short section describing how NIS integrates specifically with Slurm’s authentication (UID consistency, job submission, and accounting)**?
That would make the guide even more complete for HPC documentation.
