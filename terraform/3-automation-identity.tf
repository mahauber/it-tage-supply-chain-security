####################
## GitHub Actions ##
####################

resource "azurerm_user_assigned_identity" "github" {
  name                = "id-github"
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
}

resource "azurerm_role_assignment" "github" {
  for_each = toset([
    "Key Vault Administrator",
    "Storage Blob Data Owner",
    "Contributor",
    "Azure Kubernetes Service RBAC Cluster Admin",
    "AcrPush"
  ])
  scope                = "/subscriptions/${var.subscription_id}"
  role_definition_name = each.value
  principal_id         = azurerm_user_assigned_identity.github.principal_id
}

resource "azurerm_federated_identity_credential" "github" {
  for_each = toset(["dev", "dev-approval", "prod", "prod-approval", "common", "common-approval"])

  name                = "github-${each.key}"
  resource_group_name = azurerm_user_assigned_identity.github.resource_group_name
  audience            = ["api://AzureADTokenExchange"]
  issuer              = "https://token.actions.githubusercontent.com"
  parent_id           = azurerm_user_assigned_identity.github.id
  subject             = "repo:mahauber/it-tage-supply-chain-security:environment:${each.key}"
}