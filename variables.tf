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