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
