variable "resource_group_name" {
  description = "The name of the existing Azure Resource Group to deploy resources into."
  type        = string
}

variable "location" {
  description = "The Azure region for the resources (e.g., westeurope, eastus)."
  type        = string
  default     = "westeurope"
}

variable "admin_public_ip" {
  description = "The Public IP address of the administrator (You) to allow SSH access. Use '0.0.0.0/0' for open access (not recommended)."
  type        = string
}