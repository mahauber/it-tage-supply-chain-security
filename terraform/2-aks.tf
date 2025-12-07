resource "azurerm_kubernetes_cluster" "aks" {
  name                              = var.aks_name
  location                          = azurerm_resource_group.main.location
  resource_group_name               = azurerm_resource_group.main.name
  dns_prefix                        = "kubernetes"
  oidc_issuer_enabled               = true
  workload_identity_enabled         = true
  local_account_disabled            = true
  role_based_access_control_enabled = true
  run_command_enabled               = false
  kubernetes_version                = "1.33.5"

  network_profile {
    network_plugin      = "azure"
    network_policy      = "cilium"
    network_data_plane  = "cilium"
    network_plugin_mode = "overlay"
    pod_cidr            = "100.96.0.0/12"
    service_cidr        = "100.112.0.0/12"
    dns_service_ip      = "100.112.0.10"
    outbound_type       = "loadBalancer"
  }

  default_node_pool {
    name       = "default"
    node_count = var.aks_node_count
    vm_size    = var.aks_vm_size
  }

  identity {
    type = "SystemAssigned"
  }

  lifecycle {
    ignore_changes = [
      default_node_pool[0].upgrade_settings,
      default_node_pool[0].tags
    ]
  }

  azure_active_directory_role_based_access_control {
    azure_rbac_enabled = true
    tenant_id          = data.azurerm_client_config.current.tenant_id
  }
}

resource "azurerm_role_assignment" "aks_acr_pull" {
  principal_id                     = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
  role_definition_name             = "AcrPull"
  scope                            = azurerm_container_registry.acr.id
  skip_service_principal_aad_check = true
}
