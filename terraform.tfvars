location = "East US"
environment = "dev"

tags = {
  Environment = "dev"
  Project     = "sp-terraform-project2"
  ManagedBy   = "Terraform"
}

resource_group_name = "sp-terraform-project2-rg"

# Network Configuration
vnet_name = "sp-terraform-vnet"
subnet_name = "public-subnet"

# VM Configuration
vm_name = "sp-terraform-vm"
admin_username = "azureuser"

# Key Vault Configuration (update with your actual Key Vault details)
key_vault_name = "sp-terraform-kv"
key_vault_resource_group = "sp-terraform-project2-rg"
vm_password_secret_name = "vm-admin-password"

# Scale Set Configuration
scale_set_name = "sp-terraform-vmss"
scale_set_capacity = 3
