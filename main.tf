terraform {
  required_providers {
    proxmox = {
      source = "Telmate/proxmox"
    }
  }
}

locals {
  vm_settings = {
    "k3s-ctrl-1" = { macaddr = "7A:00:00:00:01:01", cores = 4, ram = 8192, vmid = 901 },
    "k3s-ctrl-2" = { macaddr = "7A:00:00:00:01:02", cores = 4, ram = 8192, vmid = 902 },
    "k3s-ctrl-3" = { macaddr = "7A:00:00:00:01:03", cores = 4, ram = 8192, vmid = 903 },
    "k3s-cmp-1"  = { macaddr = "7A:00:00:00:01:04", cores = 4, ram = 8192, vmid = 904 },
    "k3s-cmp-2"  = { macaddr = "7A:00:00:00:01:05", cores = 4, ram = 8192, vmid = 905 },
    "k3s-cmp-3"  = { macaddr = "7A:00:00:00:01:06", cores = 4, ram = 8192, vmid = 906 },
    "k3s-mysql"  = { macaddr = "7a:00:00:00:01:07", cores = 1, ram = 4096, vmid = 907 },
    "k3s-nginx"  = { macaddr = "7a:00:00:00:01:08", cores = 1, ram = 4096, vmid = 908 }
  }
  bridge = "vmbr0"
  lxc_settings = {

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

/* Configure cloud-init User-Data with custom config file */
resource "proxmox_vm_qemu" "cloudinit_nodes" {
  for_each    = local.vm_settings
  name        = each.key
  vmid        = each.value.vmid
  target_node = var.target_host
  clone       = var.template_name
  full_clone  = false
  boot        = "cdn" # "c" by default, which renders the coreos35 clone non-bootable. "cdn" is HD, DVD and Network
  oncreate    = true  # start once created
  agent       = 0

  cores    = each.value.cores
  memory   = each.value.ram
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
    bridge  = local.bridge
    macaddr = each.value.macaddr
  }
}
