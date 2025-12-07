resource "azurerm_key_vault" "kv" {
  name                = "kv-supply-chain-demo"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  sku_name                    = "standard"
  enabled_for_deployment      = true
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 7
  rbac_authorization_enabled  = true
}

resource "azurerm_key_vault_key" "github_actions_cosign" {
  name         = "github-actions-cosign-key-simple-service"
  key_vault_id = azurerm_key_vault.kv.id
  key_type     = "EC"
  curve        = "P-256"

  key_opts = [
    "sign",
    "verify"
  ]
}