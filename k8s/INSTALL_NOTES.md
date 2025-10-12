# 🛠 Raspberry Pi Kubernetes Cluster — Installation Notes

> Set-up guide for a 3-node Raspberry Pi 5 homelab cluster with **k3s** (lightweight Kubernetes).

---

## 1️⃣ Prerequisites

- Raspberry Pi 5 × 3, each with **8 GB RAM**  
- 64–128 GB microSD card per Pi  
- Ethernet connection via switch  
- Desktop PC with Wi-Fi internet access for bridging  
- SSH enabled on all Pis

---

## 2️⃣ Flash Raspberry Pi OS (64-bit Lite)

1. Download **Raspberry Pi OS Lite (64-bit)** from [raspberrypi.com](https://www.raspberrypi.com/software/).  
2. Flash each SD card using **Raspberry Pi Imager**.  
3. Enable SSH by creating an empty file named `ssh` in the boot partition.  
4. Set a hostname via `hostname` file:
   ```
   pi-master
   pi-node1
   pi-node2
   ```

---

## 3️⃣ Boot & Connect

1. Insert SD cards into Pis, power them on.  
2. Connect all Pis to the switch.  
3. From desktop, find the IPs:
   ```bash
   nmap -sn 192.168.1.0/24
   ```
4. SSH into each Pi:
   ```bash
   ssh pi@192.168.1.11  # Pi-master
   ssh pi@192.168.1.12  # Pi-node1
   ssh pi@192.168.1.13  # Pi-node2
   ```

---

## 4️⃣ Update & Prepare Pis

On **all nodes**:
```bash
sudo apt update && sudo apt full-upgrade -y
sudo reboot
```

---

## 5️⃣ Install k3s on the Master Node (Pi-1)

```bash
curl -sfL https://get.k3s.io | sh -
```

- Wait a minute for k3s to start.  
- Verify installation:
```bash
sudo k3s kubectl get nodes
```

- Issue encountered:
  Error: failed to find memory cgroup (v2)
  Control Groups (cgroups) are a Linux kernel feature that lets the OS limit, isolate, and measure how much CPU, memory, and I/O each process (or group of processes) can use.
  Troubleshoot and fix:
```bash
sudo systemctl start k3s
sudo systemctl status k3s
sudo journalctl -xeu k3s.service | tail -n 40
sudo sed -i '$ s/$/ cgroup_memory=1 cgroup_enable=memory/' /boot/firmware/cmdline.txt
cat /boot/firmware/cmdline.txt
sudo reboot
grep cgroup /proc/filesystems
sudo systemctl start k3s
sudo systemctl status k3s
sudo k3s kubectl get nodes

> Only the master node will appear for now.
  
```bash

- Retrieve the join token for workers:
```bash
sudo cat /var/lib/rancher/k3s/server/node-token
```

---

## 6️⃣ Join Worker Nodes (Pi-2 & Pi-3)

On **each worker node**, run:

```bash
curl -sfL https://get.k3s.io | K3S_URL=https://<MASTER_IP>:6443 K3S_TOKEN=<NODE_TOKEN> sh -
```

- Replace `<MASTER_IP>` with the Pi-master IP (e.g., `192.168.1.11`)  
- Replace `<NODE_TOKEN>` with the token from step 5.

---

## 7️⃣ Verify Cluster

On the **master node** (or desktop with `kubectl` configured):
```bash
sudo k3s kubectl get nodes
```

You should see all 3 nodes with status `Ready`:

```
NAME          STATUS   ROLES           AGE
pi-master     Ready    master          5m
pi-node1      Ready    <none>          2m
pi-node2      Ready    <none>          1m
```

---

## 8️⃣ Optional Post-Setup

- Label worker nodes:
```bash
sudo k3s kubectl label node pi-node1 node-role.kubernetes.io/worker=worker
sudo k3s kubectl label node pi-node2 node-role.kubernetes.io/worker=worker
```

- Install Kubernetes dashboard or monitoring stack (Grafana + Prometheus).  
- Test workloads:
```bash
sudo k3s kubectl create deployment nginx --image=nginx
sudo k3s kubectl get pods -A
```

- Enable automatic updates (optional):
```bash
sudo apt install unattended-upgrades -y
```

---

## ⚡ Notes

- Keep hostnames and IPs consistent to avoid `k3s` re-joining issues.  
- **Educational use**, not production workloads.

---
