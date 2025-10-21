# 🧠 PXE & Netboot Troubleshooting Guide

This document addresses common issues encountered when operating the Raspberry Pi HPC cluster in **PXE (network boot)** mode.  
Since all compute nodes — and sometimes even `hpc_master` — boot from **NFS-mounted root filesystems**, several permissions, networking, and package management behaviors differ from traditional SD card installations.

---

## 1. Filesystem Behavior and Permissions

When nodes boot via PXE/NFS, their root filesystem type is `nfs`.  
You can verify this by checking any binary’s mount point:

```bash
df -T $(which ping)
````

Because the filesystem is shared and managed remotely:

* Some executables (like `/bin/ping`) may **lose their setuid bit** during export.
* As a result, normal users cannot run commands requiring elevated privileges.

### Fix

Use `sudo` for affected commands (e.g., `sudo ping <addr>`), or, if needed, restore permissions:

```bash
sudo chmod u+s /bin/ping
```

> ⚠️ Avoid altering permissions globally on shared NFS images unless strictly necessary.

---

## 2. Package Installation via `apt` on Netbooted Systems

PXE/NFS setups often isolate worker nodes from direct internet access.
To allow `apt` installations or system updates on `hpc_master`, we configure a **proxy server** on the **login node** using **Squid**.

### Steps to Configure Squid Proxy

1. **Install Squid** on the login node:

   ```bash
   sudo apt install squid
   ```

2. **Edit the configuration**:

   ```bash
   sudo nano /etc/squid/squid.conf
   ```

   Add the following lines **above** `http_access deny all`:

   ```
   acl localnet src 192.168.2.117
   http_access allow localnet
   ```

3. **Restart Squid**:

   ```bash
   sudo systemctl restart squid
   ```

4. **Configure proxy environment variables** on `hpc_master`
   Append to `~/.bashrc`:

   ```bash
   export http_proxy="http://192.168.2.1:3128"
   export https_proxy="http://192.168.2.1:3128"
   ```

5. **Create APT proxy configuration**:

   ```bash
   sudo nano /etc/apt/apt.conf
   ```

   Add:

   ```
   Acquire::http::Proxy "http://192.168.2.1:3128";
   Acquire::https::Proxy "http://192.168.2.1:3128";
   ```

After saving, you should be able to run:

```bash
sudo apt update
sudo apt install <package>
```

without timeouts or unreachable repository errors.

---

## 3. Common APT / Package Management Errors

### Permission Errors (`/var/cache/man`)

You may encounter messages like:

```
/usr/bin/mandb: fopen /var/cache/man/zh_CN/42094: Permission denied
```

**Fix:**

```bash
sudo chown -R root:man /var/cache/man
sudo chmod -R g+w /var/cache/man
```

---

### `flash-kernel` Fails During Upgrades

The `flash-kernel` package attempts to write to boot partitions, which are **absent in PXE-booted systems**.

**Fix:**
Remove it permanently:

```bash
sudo apt remove flash-kernel
```

---

### `initramfs-tools` Fails During Upgrades

Because the filesystem is network-mounted, the `initramfs-tools` package may fail when updating or rebuilding initrd images.

**Fix:**
This issue is currently **unresolved** and can be safely ignored, since PXE systems do not rely on local initramfs images for booting.

---

## 4. Kernel Upgrade Issues

During a system upgrade, `apt` may update the Raspberry Pi kernel (e.g., from `vmlinuz-6.8.0-1010-raspi` to `vmlinuz-6.8.0-1020-raspi`).
Sometimes the new kernel file’s permissions are incorrect, leading to a non-bootable state.

### Detection

Check logs with:

```bash
journalctl -xb
```

### Fix

Grant execute permission to the new kernel image:

```bash
sudo chmod 755 /boot/vmlinuz-6.8.0-1020-raspi
sudo reboot
```

---

## 5. Key Takeaways

* PXE-booted systems behave differently because their root filesystem is mounted via NFS.
* Always use a **proxy** for `apt` operations if the master lacks direct internet access.
* Avoid `flash-kernel` and similar low-level boot packages on diskless systems.
* Monitor kernel updates carefully; permission errors can prevent successful reboots.
