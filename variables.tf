variable "api_url" {
  description = "URL to the API of Proxmox"
  default     = "https://192.168.1.101:8006/api2/json"
}
variable "user" {
  description = "Name of the admin account to use"
  default     = "terraform-prov@pve"
}
variable "passwd" {
  description = "Password for the user - defined elsewhere"
  type        = string
  sensitive   = true
}

variable "target_host" {
  description = "hostname to deploy to"
  default     = "dantooine"
}

variable "lxc_passwd" {
  description = "Password for the root user on containers"
  type        = string
  sensitive   = true
}

variable "storage_name" {
  description = "Storage name on Proxmox server"
  default     = "vm-data"
}
variable "template_name" {
  description = "Name of the template to clone"
  default     = "u-cloudimg"
}
variable "pool" {
  default = "prod"
}
variable "master_count" {
  default = 1
}
variable "master_prefix" {
  default = "prod-k3s-ctrl"
}
variable "compute_prefix" {
  default = "prod-k3s-cmp"
}
variable "storage_prefix" {
  default = "prod-k3s-lh"
}

variable "haproxy_prefix" {
  default = "prod-k3s-nginx"
}

variable "mysql_prefix" {
  default = "prod-k3s-mysql"
}
variable "master_ram" {
  default = 16384
}
variable "master_cores" {
  default = 4
}
variable "compute_count" {
  default = 3
}
variable "compute_ram" {
  default = 16384
}
variable "compute_cores" {
  default = 4
}
variable "network_bridge" {
  default = "vmbr0"
}
variable "storage_count" {
  default = 1
}
variable "storage_ram" {
  default = 16384
}

variable "storage_cores" {
  default = 4
}

variable "network_vlan" {
  default = 1
}

variable "mastermac" {
  type    = list(string)
  default = ["7A:00:00:00:01:01", "7A:00:00:00:01:02", "7A:00:00:00:01:03"]
}
variable "mastervmid" {
  type    = list(number)
  default = [901, 902, 903]
}

variable "workermac" {
  type    = list(string)
  default = ["7A:00:00:00:01:04", "7A:00:00:00:01:05", "7A:00:00:00:01:06"]
}
variable "storagemac" {
  type    = list(string)
  default = ["7A:00:00:00:01:09"]
  #default = ["7A:00:00:00:01:09", "7A:00:00:00:01:0a", "7A:00:00:00:01:0b"]
}

variable "workervmid" {
  type    = list(number)
  default = [904, 905, 906]
}

variable "mysqlmac" {
  type    = string
  default = "7A:00:00:00:01:07"
}
variable "mysqlvmid" {
  type    = number
  default = 907
}
variable "haproxyvmid" {
  type    = number
  default = 908
}
variable "storagevmid" {
  type    = list(number)
  default = [909]
  #default = [909, 910, 911]
}


variable "haproxymac" {
  type    = string
  default = "7A:00:00:00:01:08"
}
