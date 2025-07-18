# Key Vault setup (run this first if Key Vault doesn't exist)
resource "azurerm_key_vault" "main" {
  name                       = var.key_vault_name
  location                   = azurerm_resource_group.main.location
  resource_group_name        = azurerm_resource_group.main.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  soft_delete_retention_days = 7

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    secret_permissions = [
      "Get",
      "List",
      "Set",
      "Delete",
      "Recover",
      "Backup",
      "Restore"
    ]
  }

  tags = var.tags
}

# VM Password Secret (uncomment and set a secure password)
resource "azurerm_key_vault_secret" "vm_password" {
  name         = var.vm_password_secret_name
  value        = "ChangeMe123!" # Change this to a secure password
  key_vault_id = azurerm_key_vault.main.id

  tags = var.tags
}
