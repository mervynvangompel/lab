# 🧩 Raspberry Pi Kubernetes Cluster Topology

## Overview

A compact 3-node Raspberry Pi 5 cluster for learning Docker and Kubernetes.  
All nodes are networked via a TP-Link 5-Port Gigabit Switch, managed from a desktop PC connected over Ethernet.

---

## 🖥️ Hardware

| Component | Model / Specs | Role |
|------------|----------------|------|
| **Desktop PC** | Lenovo ThinkCentre M920s — Intel® Core™ i5-8500 ×6 | Admin / Monitoring / kubectl client |
| **Switch** | TP-Link LS105G — 5-Port Gigabit Ethernet | Cluster network backbone |
| **Raspberry Pi 5 (x3)** | 8 GB RAM each | Kubernetes master (1) + workers (2) |
| **Power Supply** | USB-C multi-port (100 W+) | Powers all 3 Pis |
| **Storage** | 64 GB microSD (per Pi) or USB SSD | OS + workloads |
| **Network Cables** | Cat6 Ethernet (x3–4) | Node interconnects |

---

## 🌐 Network Configuration

| Device | IP Address | Hostname | Role |
|---------|-------------|----------|------|
| Desktop | 192.168.1.10 | `control` | kubectl client |
| Pi-1 | 192.168.1.11 | `pi-master` | K8s control plane |
| Pi-2 | 192.168.1.12 | `pi-node1` | Worker node |
| Pi-3 | 192.168.1.13 | `pi-node2` | Worker node |

> 💡 Assign static IPs via your router’s DHCP reservation settings.

---

## ⚙️ Software Stack

| Layer | Tool / Version | Notes |
|--------|----------------|-------|
| OS | Raspberry Pi OS (64-bit) | Lite version recommended |
| Container Runtime | Docker / containerd | For K8s compatibility |
| Kubernetes | k3s (lightweight) | Easiest for ARM clusters |
| Networking | flannel / cilium | Optional, for pod networking |
| Storage | local-path-provisioner | Default with k3s |
| Monitoring | Grafana + Prometheus | Optional |

---
