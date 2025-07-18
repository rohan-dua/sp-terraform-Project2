# Resource Configuration Variables
variable "location" {
  description = "Azure region where resources will be created"
  type        = string
  default     = "East US"
  
  validation {
    condition = contains([
      "East US", "East US 2", "West US", "West US 2", "West US 3",
      "Central US", "North Central US", "South Central US"
    ], var.location)
    error_message = "Location must be a valid Azure region."
  }
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

# Common Tags
variable "tags" {
  description = "A map of tags to assign to resources"
  type        = map(string)
  default = {
    Environment = "Development"
    Project     = "sp-terraform-project2"
    ManagedBy   = "Terraform"
  }
}

variable "resource_group_name" {
  description = "Name of the resource group to create"
  type        = string
  default     = "resource-group"
}

# Network Configuration
variable "vnet_name" {
  description = "Name of the virtual network"
  type        = string
  default     = "sp-terraform-vnet"
}

variable "vnet_address_space" {
  description = "Address space for the virtual network"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "subnet_name" {
  description = "Name of the subnet"
  type        = string
  default     = "public-subnet"
}

variable "subnet_address_prefix" {
  description = "Address prefix for the subnet"
  type        = string
  default     = "10.0.1.0/24"
}

# VM Configuration
variable "vm_name" {
  description = "Name of the virtual machine"
  type        = string
  default     = "sp-terraform-vm"
}

variable "vm_size" {
  description = "Size of the virtual machine"
  type        = string
  default     = "Standard_B2s"
}

variable "admin_username" {
  description = "Admin username for the VM"
  type        = string
  default     = "azureuser"
}

# Key Vault Configuration
variable "key_vault_name" {
  description = "Name of the existing Key Vault containing VM password"
  type        = string
  default     = "sp-terraform-kv"
}

variable "key_vault_resource_group" {
  description = "Resource group of the existing Key Vault"
  type        = string
  default     = "sp-terraform-project2-rg"
}

variable "vm_password_secret_name" {
  description = "Name of the secret in Key Vault containing VM password"
  type        = string
  default     = "vm-admin-password"
}

# Scale Set Configuration
variable "scale_set_name" {
  description = "Name of the Virtual Machine Scale Set"
  type        = string
  default     = "sp-terraform-vmss"
}

variable "scale_set_capacity" {
  description = "Initial capacity of the scale set"
  type        = number
  default     = 3
}

variable "availability_zones" {
  description = "Availability zones for the scale set"
  type        = list(string)
  default     = ["1", "2", "3"]
}