# NIS Server/Client Setup Guide

This guide provides a complete and clear setup for NIS (Network Information Service) in a Linux environment.

---

## Step-by-step Setup

### Step 1: Install Required Packages

**On both NIS Server and Clients:**

```bash
sudo apt-get install rpcbind nis -y
```

---

### Step 2: Set the NIS Domain Name

**On both Server and Client:**

```bash
sudo nisdomainname hpcnisdom
echo "hpcnisdom" | sudo tee /etc/defaultdomain
```

> `nisdomainname` sets the runtime domain name.
> `/etc/defaultdomain` makes it persistent across reboots.
> `/etc/defaultdomain` was not already made.
---

### Step 3: Configure `/etc/yp.conf`

**On the Client:**

```bash
echo "domain hpcnisdom server 192.168.2.117" | sudo tee -a /etc/yp.conf
echo "ypserver 192.168.2.117" | sudo tee -a /etc/yp.conf
```

Address `192.168.2.1` is the IP Address of login node and was set as servername.

---

### Step 4: Allow RPC Access

**On the Client:**

```bash
echo "rpcbind: ALL" | sudo tee -a /etc/hosts.allow
```

---

### Step 5: Fix `_rpc` Missing User (If Needed)

If you see errors like:

```
rpcbind[358]: cannot get uid of "_rpc": Success
rpcbind.service: Failed with result 'exit-code'.
```

Create the missing system user:

```bash
sudo useradd --system --no-create-home --shell /usr/sbin/nologin _rpc
```

Then restart the services:

```bash
sudo systemctl restart rpcbind
sudo systemctl restart ypbind
```

Check status:

```bash
sudo systemctl status rpcbind
sudo systemctl status ypbind
```

---

### Step 6: Enable NIS Maps on Server

**On the NIS Server:**

In `/etc/default/nis` or equivalent configuration file, make sure:

```bash
NISMASTER=YES
```

Also, ensure the NIS domain is set and matches:

```bash
sudo nisdomainname hpcnisdom
```

Then start the NIS service:

```bash
sudo systemctl restart ypserv
```

---

### Step 7: Create a Shared User

**On the NIS Server:**

```bash
sudo useradd -m -u 1100 -s /bin/bash shareduser
sudo passwd shareduser
sudo usermod -aG sudo shareduser
```

> `-u 1100` assigns a consistent UID across machines.
> Add to `sudo` if needed.

Then update NIS database:

```bash
sudo make -C /var/yp
```

---

### Step 8: Modify `/etc/nsswitch.conf` (on Client)

This file controls name service lookup order. Edit `/etc/nsswitch.conf` as follows:

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

---

### Step 9: Allow NIS Lookups (Compatibility)

To allow NIS to fetch accounts:

```bash
sudo echo '+::::::'   | sudo tee -a /etc/passwd
sudo echo '+:::'      | sudo tee -a /etc/group
sudo echo '+::::::::' | sudo tee -a /etc/shadow
```

---

### Step 10: Optional - Allow Shareduser Password-less sudo

```bash
echo "shareduser ALL=(ALL) NOPASSWD: ALL" | sudo tee -a /etc/sudoers
```

---

## Final Checks

* **Check domain name** (must be the same on server and clients):

```bash
domainname
# Output: hpcnisdom
```

* **Check if ypbind knows the NIS Server:**

```bash
ypwhich
# Output: 192.168.2.117 (your NIS server IP)
```

* **On the server, list users managed by NIS:**

```bash
ypcat passwd
```

---

## Notes

* When adding new users on the **NIS Server**, always run:

```bash
sudo make -C /var/yp
```

to regenerate NIS maps.

* Ensure **firewall** allows NIS ports (`rpcbind`, `ypbind`, etc.), or disable UFW temporarily during setup:

```bash
sudo ufw disable
```

