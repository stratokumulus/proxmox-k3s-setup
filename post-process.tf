# Here I am removing the control plane nodes from the load balancer config
resource "null_resource" "set_lb_nodes" {
  depends_on = [
    null_resource.create_kubeconfig
  ]
  for_each = toset(proxmox_vm_qemu.compute[*].name)

  provisioner "local-exec" {
    command = "KUBECONFIG=./files/kubeconfig-k3s kubectl label node ${each.value} svccontroller.k3s.cattle.io/enablelb=true"
  }
}

# And here, I'm configuring the Longhorn nodes as dedicated storage nodes
resource "null_resource" "set_longhorn_nodes" {
  depends_on = [
    null_resource.create_kubeconfig
  ]
  for_each = toset(proxmox_vm_qemu.storage[*].name)

  provisioner "local-exec" {
    command = "KUBECONFIG=./files/kubeconfig-k3s kubectl label node ${each.value} node.longhorn.io/create-default-disk=true"
  }
}

