# Raspberry Pi K3s Cluster Setup Guide

## Hardware Overview
- 3x Raspberry Pi 4 (4GB RAM)
- 1x Network switch
- Ethernet cables
- Power supplies

## Cluster Architecture
- **pi-master** (192.168.1.10) - Control plane
- **pi-worker1** (192.168.1.11) - Worker node
- **pi-worker2** (192.168.1.12) - Worker node

---

## Phase 1: Physical Setup

### 1. Configure Static IPs (on each Pi)

```bash
# SSH into each Pi (one at a time)
sudo nano /etc/dhcpcd.conf

# Add at the end (adjust IP per node):
interface eth0
static ip_address=192.168.1.10/24  # Change to .11, .12 for workers
static routers=192.168.1.1
static domain_name_servers=192.168.1.1 8.8.8.8

# Save and reboot
sudo reboot
```

### 2. Set Hostnames

```bash
# On master:
sudo hostnamectl set-hostname pi-master

# On worker1:
sudo hostnamectl set-hostname pi-worker1

# On worker2:
sudo hostnamectl set-hostname pi-worker2

sudo reboot
```

### 3. Test Connectivity

```bash
# From Ubuntu desktop:
ping 192.168.1.10
ping 192.168.1.11
ping 192.168.1.12
```

---

## Phase 2: SSH Key Setup

```bash
# On Ubuntu desktop:
ssh-keygen -t ed25519 -f ~/.ssh/raspi_cluster -C "raspi-k8s"

# Copy to all Pis:
ssh-copy-id -i ~/.ssh/raspi_cluster.pub pi@192.168.1.10
ssh-copy-id -i ~/.ssh/raspi_cluster.pub pi@192.168.1.11
ssh-copy-id -i ~/.ssh/raspi_cluster.pub pi@192.168.1.12

# Test:
ssh -i ~/.ssh/raspi_cluster pi@192.168.1.10
```

---

## Phase 3: Project Structure

```bash
mkdir -p ~/raspi-k8s-cluster/{ansible/{inventory,playbooks},kubernetes/manifests,docs}
cd ~/raspi-k8s-cluster
```

### Ansible Inventory

Create `ansible/inventory/hosts.yml`:

```yaml
all:
  children:
    masters:
      hosts:
        pi-master:
          ansible_host: 192.168.1.10
    workers:
      hosts:
        pi-worker1:
          ansible_host: 192.168.1.11
        pi-worker2:
          ansible_host: 192.168.1.12
  vars:
    ansible_user: pi
    ansible_ssh_private_key_file: ~/.ssh/raspi_cluster
    ansible_python_interpreter: /usr/bin/python3
```

### Test Ansible

```bash
cd ansible
ansible all -i inventory/hosts.yml -m ping
```

---

## Phase 4: Ansible Playbooks

### Playbook 1: Prepare Nodes

Create `ansible/playbooks/00-prepare-nodes.yml`:

```yaml
---
- name: Prepare all Raspberry Pi nodes for K3s
  hosts: all
  become: yes
  tasks:
    - name: Update apt cache
      apt:
        update_cache: yes
        cache_valid_time: 3600
        
    - name: Upgrade all packages
      apt:
        upgrade: dist
        
    - name: Install required packages
      apt:
        name:
          - curl
          - git
          - vim
          - htop
          - net-tools
        state: present
        
    - name: Enable legacy iptables
      alternatives:
        name: iptables
        path: /usr/sbin/iptables-legacy
        
    - name: Enable cgroups in boot config
      lineinfile:
        path: /boot/cmdline.txt
        backrefs: yes
        regexp: '^(.*rootwait.*)$'
        line: '\1 cgroup_enable=cpuset cgroup_memory=1 cgroup_enable=memory'
      register: boot_config
      
    - name: Disable swap
      command: swapoff -a
      
    - name: Remove swap from fstab
      lineinfile:
        path: /etc/fstab
        regexp: '^.*swap.*$'
        state: absent
        
    - name: Reboot if needed
      reboot:
        reboot_timeout: 300
      when: boot_config.changed
```

**Run:** `ansible-playbook -i inventory/hosts.yml playbooks/00-prepare-nodes.yml`

### Playbook 2: Install K3s Master

Create `ansible/playbooks/01-install-k3s-master.yml`:

```yaml
---
- name: Install K3s on master node
  hosts: masters
  become: yes
  tasks:
    - name: Install K3s server
      shell: |
        curl -sfL https://get.k3s.io | sh -s - server \
          --disable traefik \
          --write-kubeconfig-mode 644 \
          --node-name {{ inventory_hostname }}
      args:
        creates: /usr/local/bin/k3s
        
    - name: Wait for K3s
      wait_for:
        path: /etc/rancher/k3s/k3s.yaml
        timeout: 300
        
    - name: Get node token
      slurp:
        src: /var/lib/rancher/k3s/server/node-token
      register: k3s_token_raw
      
    - name: Set token fact
      set_fact:
        k3s_token: "{{ k3s_token_raw.content | b64decode | trim }}"
        
    - name: Get kubeconfig
      slurp:
        src: /etc/rancher/k3s/k3s.yaml
      register: kubeconfig_raw
      
    - name: Save kubeconfig locally
      copy:
        content: "{{ kubeconfig_raw.content | b64decode | regex_replace('127.0.0.1', ansible_host) }}"
        dest: "{{ playbook_dir }}/../../kubeconfig"
        mode: '0600'
      delegate_to: localhost
```

**Run:** `ansible-playbook -i inventory/hosts.yml playbooks/01-install-k3s-master.yml`

**Test:**
```bash
export KUBECONFIG=~/raspi-k8s-cluster/kubeconfig
kubectl get nodes
```

### Playbook 3: Join Workers

Create `ansible/playbooks/02-install-k3s-workers.yml`:

```yaml
---
- name: Get K3s token from master
  hosts: masters
  become: yes
  tasks:
    - name: Read node token
      slurp:
        src: /var/lib/rancher/k3s/server/node-token
      register: k3s_token_raw
      
    - name: Set token fact
      set_fact:
        k3s_token: "{{ k3s_token_raw.content | b64decode | trim }}"

- name: Install K3s agent on workers
  hosts: workers
  become: yes
  vars:
    k3s_url: "https://{{ hostvars['pi-master']['ansible_host'] }}:6443"
    k3s_token: "{{ hostvars['pi-master']['k3s_token'] }}"
  tasks:
    - name: Install K3s agent
      shell: |
        curl -sfL https://get.k3s.io | K3S_URL={{ k3s_url }} \
          K3S_TOKEN={{ k3s_token }} \
          sh -s - agent --node-name {{ inventory_hostname }}
      args:
        creates: /usr/local/bin/k3s-agent
```

**Run:** `ansible-playbook -i inventory/hosts.yml playbooks/02-install-k3s-workers.yml`

**Verify:** `kubectl get nodes` (should show all 3)

---

## Phase 5: Deploy Test Application

Create `kubernetes/manifests/nginx-demo.yml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-demo
spec:
  replicas: 2
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:alpine
        ports:
        - containerPort: 80
        resources:
          requests:
            memory: "64Mi"
            cpu: "100m"
          limits:
            memory: "128Mi"
            cpu: "200m"
---
apiVersion: v1
kind: Service
metadata:
  name: nginx-service
spec:
  type: NodePort
  selector:
    app: nginx
  ports:
  - port: 80
    targetPort: 80
    nodePort: 30080
```

**Deploy:**
```bash
kubectl apply -f kubernetes/manifests/nginx-demo.yml
kubectl get pods
kubectl get svc
```

**Access:** `http://192.168.1.11:30080` in browser

---

## Troubleshooting

### Nodes not Ready
```bash
kubectl describe node pi-worker1
journalctl -u k3s -f  # on master
journalctl -u k3s-agent -f  # on worker
```

### Can't connect to cluster
```bash
# Check K3s is running:
sudo systemctl status k3s  # on master
sudo systemctl status k3s-agent  # on workers

# Restart if needed:
sudo systemctl restart k3s
```

### Pods pending
```bash
kubectl describe pod <pod-name>
kubectl get events --sort-by='.lastTimestamp'
```

---

## GitHub Repo Structure

```
raspi-k8s-cluster/
├── README.md
├── SETUP-GUIDE.md (this file)
├── kubeconfig
├── ansible/
│   ├── inventory/
│   │   └── hosts.yml
│   └── playbooks/
│       ├── 00-prepare-nodes.yml
│       ├── 01-install-k3s-master.yml
│       └── 02-install-k3s-workers.yml
├── kubernetes/
│   └── manifests/
│       └── nginx-demo.yml
└── docs/
    ├── architecture.md
    └── lessons-learned.md
```

---

## Next Steps

1. Add monitoring (Prometheus/Grafana)
2. Set up persistent storage
3. Deploy more complex apps
4. Practice CKA exam scenarios
5. Document your journey!

---

## Useful Commands

```bash
# Cluster info
kubectl cluster-info
kubectl get nodes -o wide
kubectl get pods --all-namespaces

# Uninstall K3s (if needed)
# On master:
/usr/local/bin/k3s-uninstall.sh
# On workers:
/usr/local/bin/k3s-agent-uninstall.sh
```
