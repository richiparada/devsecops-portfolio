# Azure Kubernetes Service (AKS)

# User-assigned managed identity for AKS
resource "azurerm_user_assigned_identity" "aks" {
  name                = "${local.resource_prefix}-aks-identity"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = local.common_tags
}

# AKS Cluster
resource "azurerm_kubernetes_cluster" "main" {
  name                = "${local.resource_prefix}-aks"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  dns_prefix          = "${local.resource_prefix}-aks"
  kubernetes_version  = var.kubernetes_version
  
  # Security: Enable Azure AD integration
  azure_active_directory_role_based_access_control {
    managed                = true
    admin_group_object_ids = var.admin_group_object_ids
    azure_rbac_enabled     = true
  }
  
  # Default node pool (system)
  default_node_pool {
    name                = "system"
    node_count          = 2
    vm_size             = "Standard_D2s_v3"
    vnet_subnet_id      = azurerm_subnet.aks.id
    type                = "VirtualMachineScaleSets"
    enable_auto_scaling = true
    min_count           = 2
    max_count           = 5
    max_pods            = 30
    
    # Security: Enable node OS auto-upgrade
    os_disk_size_gb = 128
    os_disk_type    = "Managed"
    
    upgrade_settings {
      max_surge = "33%"
    }
    
    tags = local.common_tags
  }
  
  # Identity
  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.aks.id]
  }
  
  # Network profile
  network_profile {
    network_plugin     = "azure"
    network_policy     = "azure"
    load_balancer_sku  = "standard"
    service_cidr       = "10.1.0.0/16"
    dns_service_ip     = "10.1.0.10"
  }
  
  # Security: Enable Azure Policy for Kubernetes
  azure_policy_enabled = true
  
  # Security: Enable Key Vault Secrets Provider
  key_vault_secrets_provider {
    secret_rotation_enabled  = true
    secret_rotation_interval = "2m"
  }
  
  # Security: Enable Microsoft Defender
  microsoft_defender {
    log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id
  }
  
  # Monitoring
  oms_agent {
    log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id
  }
  
  # Security: Enable HTTP application routing (disable in production)
  http_application_routing_enabled = false
  
  # Security: Enable private cluster (optional, can make management harder)
  # private_cluster_enabled = true
  
  # Maintenance window
  maintenance_window {
    allowed {
      day   = "Sunday"
      hours = [2, 3, 4]
    }
  }
  
  tags = local.common_tags
  
  depends_on = [
    azurerm_role_assignment.aks_network
  ]
}

# User node pool for applications
resource "azurerm_kubernetes_cluster_node_pool" "user" {
  name                  = "user"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.main.id
  vm_size               = "Standard_D2s_v3"
  node_count            = 2
  enable_auto_scaling   = true
  min_count             = 2
  max_count             = 10
  max_pods              = 30
  vnet_subnet_id        = azurerm_subnet.aks.id
  
  upgrade_settings {
    max_surge = "33%"
  }
  
  node_labels = {
    "workload" = "application"
  }
  
  tags = local.common_tags
}

# Role assignment: AKS to VNet
resource "azurerm_role_assignment" "aks_network" {
  scope                = azurerm_virtual_network.main.id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_user_assigned_identity.aks.principal_id
}

# Role assignment: AKS to ACR
resource "azurerm_role_assignment" "aks_acr" {
  scope                = azurerm_container_registry.main.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_kubernetes_cluster.main.kubelet_identity[0].object_id
}

# Outputs
output "aks_cluster_name" {
  value       = azurerm_kubernetes_cluster.main.name
  description = "AKS cluster name"
}

output "aks_cluster_id" {
  value       = azurerm_kubernetes_cluster.main.id
  description = "AKS cluster ID"
}

output "aks_kube_config" {
  value       = azurerm_kubernetes_cluster.main.kube_config_raw
  description = "AKS kubeconfig"
  sensitive   = true
}

output "aks_host" {
  value       = azurerm_kubernetes_cluster.main.kube_config[0].host
  description = "AKS API server endpoint"
  sensitive   = true
}
