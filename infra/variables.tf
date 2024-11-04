variable "resource_group_name" {
  description = "Resource group name"
  default     = "k3s-cluster"
  type        = string
}

variable "location" {
  description = "Azure Location"
  default     = "westeurope"
  type        = string
}

variable "cluster_master_node_sku" {
  description = "VM SKU for the master nodes"
  type        = string
}
variable "cluster_master_node_count" {
  description = "VM Count for master nodes"
  default     = 1
  type        = number
}
variable "cluster_worker_node_sku" {
  description = "VM SKU for the master nodes"
  type        = string
}
variable "cluster_worker_node_count" {
  description = "VM Count for master nodes"
  default     = 1
  type        = number
}

variable "cluster_admin_username" {
  description = "Admin user name for VMs"
  default     = "adminuser"
  type        = string
}

variable "cluster_node_ssh_public_key" {
  description = "Public SSH key for the cluster nodes"
  type        = string
}
