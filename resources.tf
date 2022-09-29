resource "local_file" "ansible_inventory" {
  content = templatefile("files/template.tmpl",
    {
      master_nodes  = proxmox_vm_qemu.master[*].name,
      master_ips    = proxmox_vm_qemu.master[*].default_ipv4_address,
      master_idx    = proxmox_vm_qemu.master[*].tags,
      worker_nodes  = proxmox_vm_qemu.compute[*].name,
      worker_ips    = proxmox_vm_qemu.compute[*].default_ipv4_address,
      worker_idx    = proxmox_vm_qemu.compute[*].tags,
      storage_nodes = proxmox_vm_qemu.storage[*].name,
      storage_ips   = proxmox_vm_qemu.storage[*].default_ipv4_address,
      storage_idx   = proxmox_vm_qemu.storage[*].tags,
      nginx_name    = proxmox_vm_qemu.haproxy.name,
      nginx_ip      = proxmox_vm_qemu.haproxy.default_ipv4_address,
      mysql_name    = proxmox_vm_qemu.mysql.name,
      mysql_ip      = proxmox_vm_qemu.mysql.default_ipv4_address
    }
  )
  filename = "inventory/hosts.ini"
}

resource "local_file" "nginx_conf" {
  content = templatefile("files/nginx.tmpl",
    {
      master_ips = proxmox_vm_qemu.master[*].default_ipv4_address,
      master_idx = proxmox_vm_qemu.master[*].tags,
      mysql_ip   = proxmox_vm_qemu.mysql.default_ipv4_address
    }
  )
  filename = "files/nginx.conf"
}


resource "null_resource" "create_kubeconfig" {
  depends_on = [
    local_file.ansible_inventory,
    local_file.nginx_conf
  ]
  provisioner "local-exec" {
    command = "sleep 180 && ansible-playbook mysql.yaml haproxy.yaml master.yaml worker.yaml"
  }
}
