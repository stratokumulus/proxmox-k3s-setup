provider "proxmox" {
  pm_api_url  = var.api_url
  pm_user     = var.user
  pm_password = var.passwd
  # Leave to "true" for self-signed certificates
  pm_tls_insecure = "true"
  pm_debug        = true
  pm_timeout      = 300
}

locals {
  vm_settings = merge(flatten([for i in fileset(".", "vars/nodes.yaml") : yamldecode(file(i))["nodes"]])...)
  network     = yamldecode(file("vars/network.yaml"))
  db          = yamldecode(file("vars/db.yaml"))
}

resource "proxmox_vm_qemu" "cloudinit-nodes" {
  for_each    = local.vm_settings
  name        = each.key
  vmid        = each.value.vmid
  target_node = var.target_host
  clone       = each.value.os
  full_clone  = true
  boot        = "order=scsi0;net0" # "c" by default, which renders the coreos35 clone non-bootable. "cdn" is HD, DVD and Network
  agent       = 0
  tags        = "k3s,${each.value.type}"
  vm_state    = each.value.boot # start once created ?

  cores    = each.value.cores
  memory   = each.value.ram
  scsihw   = "virtio-scsi-pci"
  bootdisk = "scsi0"
  hotplug  = 0

  disk {
    slot    = "scsi0"
    size    = "120G"
    type    = "disk"
    storage = "VM-DATA"
    #iothread = 1
  }
  network {
    model   = "virtio"
    bridge  = local.network.bridge
    tag     = local.network.vlan
    macaddr = each.value.macaddr
  }
}

resource "local_file" "ansible_inventory" {
  content = templatefile("templates/hosts.tmpl",
    {
      primary   = { "name" = local.vm_settings.master0.name, "ip" = local.vm_settings.master0.ip } #[for j in local.vm_settings : { "name" : j.name, "ip" : j.ip } if j.name == local.vm_settings.master0.name]
      secondary = [for j in local.vm_settings : { "name" : j.name, "ip" : j.ip } if j.type == "master" && j.name != local.vm_settings.master0.name]
      workers   = [for j in local.vm_settings : { "name" : j.name, "ip" : j.ip } if j.type == "worker"]
      nginx     = { "name" = local.vm_settings.haproxy.name, "ip" = local.vm_settings.haproxy.ip }
      mysql     = { "name" = local.vm_settings.database.name, "ip" = local.vm_settings.database.ip }
      db        = { "user" = local.db.user, "dbname" = local.db.dbname, "password" = local.db.pwd }
    }
  )
  filename = "inventory/hosts.ini"
}

resource "local_file" "nginx_conf" {
  content = templatefile("templates/nginx.tmpl",
    {
      control  = [for j in local.vm_settings : j.ip if j.type == "master"]
      mysql_ip = local.vm_settings.database.ip
    }
  )
  filename = "files/nginx.conf"
}

