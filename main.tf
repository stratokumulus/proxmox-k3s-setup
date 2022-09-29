terraform {
  required_providers {
    proxmox = {
      source  = "Telmate/proxmox"
      version = "~> 2.9.10"
    }
  }
}

provider "proxmox" {
  pm_api_url  = var.api_url
  pm_user     = var.user
  pm_password = var.passwd
  # Leave to "true" for self-signed certificates
  pm_tls_insecure = "true"
  #pm_debug = true
}

provider "helm" {
  kubernetes {
    config_path = "./files/kubeconfig-k3s"
  }
}

# Can we reuse the one from above ?
provider "kubernetes" {
  config_path = "./files/kubeconfig-k3s"
}

resource "proxmox_vm_qemu" "master" {
  count       = var.master_count
  name        = "${var.master_prefix}-${count.index}"
  desc        = "Master node"
  target_node = var.target_host
  clone       = var.template_name
  pool        = var.pool
  full_clone  = true
  boot        = "cdn" # "c" by default, which renders the coreos35 clone non-bootable. "cdn" is HD, DVD and Network
  oncreate    = true  # start once created
  onboot      = true  # start the node automatically when Proxmox starts 
  agent       = 1

  vmid = 901 + count.index

  cores    = var.master_cores
  memory   = var.master_ram
  scsihw   = "virtio-scsi-pci"
  bootdisk = "scsi0"
  hotplug  = 0

  disk {
    slot    = 0
    size    = "16G"
    type    = "scsi"
    storage = var.storage_name
    #iothread = 1
  }
  network {
    model   = "virtio"
    bridge  = var.network_bridge
    macaddr = var.mastermac[count.index]
  }

  tags = count.index
}

/* Configure cloud-init User-Data with custom config file */
resource "proxmox_vm_qemu" "compute" {
  count       = var.compute_count
  name        = "${var.compute_prefix}-${count.index}"
  desc        = "Worker node"
  target_node = var.target_host
  clone       = var.template_name
  pool        = var.pool
  full_clone  = true
  boot        = "cdn" # "c" by default, which renders the coreos35 clone non-bootable. "cdn" is HD, DVD and Network
  oncreate    = true  # start once created
  onboot      = true  # start the node automatically when Proxmox starts 
  agent       = 1

  vmid     = 904 + count.index
  cores    = var.compute_cores
  memory   = var.compute_ram
  scsihw   = "virtio-scsi-pci"
  bootdisk = "scsi0"
  hotplug  = 0

  disk {
    slot    = 0
    size    = "16G"
    type    = "scsi"
    storage = var.storage_name
    #iothread = 1
  }
  network {
    model   = "virtio"
    bridge  = var.network_bridge
    macaddr = var.workermac[count.index]

  }
  tags = count.index

}

/* Configure cloud-init User-Data with custom config file */
resource "proxmox_vm_qemu" "storage" {
  count       = var.storage_count
  name        = "${var.storage_prefix}-${count.index}"
  desc        = "Longhorn storage node"
  target_node = var.target_host
  clone       = var.template_name
  pool        = var.pool
  full_clone  = true
  boot        = "cdn" # "c" by default, which renders the coreos35 clone non-bootable. "cdn" is HD, DVD and Network
  oncreate    = true  # start once created
  onboot      = true  # start the node automatically when Proxmox starts 
  agent       = 1

  vmid     = 909 + count.index
  cores    = var.storage_cores
  memory   = var.storage_ram
  scsihw   = "virtio-scsi-pci"
  bootdisk = "scsi0"
  hotplug  = 0

  disk {
    slot    = 0
    size    = "200G"
    type    = "scsi"
    storage = var.storage_name
    #iothread = 1
  }
  network {
    model   = "virtio"
    bridge  = var.network_bridge
    macaddr = var.storagemac[count.index]

  }
  tags = count.index

}

resource "proxmox_vm_qemu" "haproxy" {
  name        = var.haproxy_prefix
  desc        = "HA Proxy"
  target_node = var.target_host
  clone       = var.template_name
  pool        = var.pool
  full_clone  = true
  boot        = "cdn" # "c" by default, which renders the coreos35 clone non-bootable. "cdn" is HD, DVD and Network
  oncreate    = true  # start once created
  onboot      = true  # start the node automatically when Proxmox starts 
  agent       = 1
  vmid        = var.haproxyvmid

  cores    = 1
  memory   = 4096
  scsihw   = "virtio-scsi-pci"
  bootdisk = "scsi0"
  hotplug  = 0

  disk {
    slot    = 0
    size    = "16G"
    type    = "scsi"
    storage = var.storage_name
    #iothread = 1
  }
  network {
    model   = "virtio"
    bridge  = var.network_bridge
    macaddr = var.haproxymac
  }
}
resource "proxmox_vm_qemu" "mysql" {
  name        = var.mysql_prefix
  desc        = "MySQL"
  target_node = var.target_host
  clone       = var.template_name
  pool        = var.pool
  full_clone  = true
  boot        = "cdn" # "c" by default, which renders the coreos35 clone non-bootable. "cdn" is HD, DVD and Network
  oncreate    = true  # start once created
  onboot      = true  # start the node automatically when Proxmox starts
  agent       = 1
  vmid        = var.mysqlvmid

  cores    = 1
  memory   = 4096
  scsihw   = "virtio-scsi-pci"
  bootdisk = "scsi0"
  hotplug  = 0

  disk {
    slot    = 0
    size    = "16G"
    type    = "scsi"
    storage = var.storage_name
    #iothread = 1
  }
  network {
    model   = "virtio"
    bridge  = var.network_bridge
    macaddr = var.mysqlmac
  }
}
