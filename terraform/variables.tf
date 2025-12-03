variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
  default     = "rg-supply-chain-demo"
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "northeurope"
}

variable "acr_name" {
  description = "Name of the Azure Container Registry"
  type        = string
  default     = "acrsupplychaindemo"
}

variable "aks_name" {
  description = "Name of the AKS cluster"
  type        = string
  default     = "aks-supply-chain-demo"
}

variable "aks_node_count" {
  description = "Number of nodes in the AKS cluster"
  type        = number
  default     = 2
}

variable "aks_vm_size" {
  description = "VM size for AKS nodes"
  type        = string
  default     = "Standard_B2ms"
}

variable "subscription_id" {
  description = "Azure Subscription ID"
  type        = string
}