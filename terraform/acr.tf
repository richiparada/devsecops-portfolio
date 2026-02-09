# Azure Container Registry

resource "azurerm_container_registry" "main" {
  name                = "${var.project_name}${var.environment}acr"  # Must be globally unique, alphanumeric only
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = "Premium"  # Premium required for security features
  admin_enabled       = false      # Security: Disable admin account
  
  # Security: Enable image quarantine
  quarantine_policy_enabled = true
  
  # Security: Enable content trust
  trust_policy {
    enabled = true
  }
  
  # Security: Enable vulnerability scanning
  # Note: This requires Microsoft Defender for Containers
  
  # Retention policy for untagged manifests
  retention_policy {
    days    = 7
    enabled = true
  }
  
  # Network rules (restrict access)
  network_rule_set {
    default_action = "Allow"  # Change to "Deny" for production with specific allow rules
    
    # Allow from AKS subnet
    virtual_network {
      action    = "Allow"
      subnet_id = azurerm_subnet.aks.id
    }
    
    # Allow from Jenkins subnet
    virtual_network {
      action    = "Allow"
      subnet_id = azurerm_subnet.jenkins.id
    }
  }
  
  # Encryption (customer-managed keys optional)
  # encryption {
  #   enabled            = true
  #   key_vault_key_id   = azurerm_key_vault_key.acr.id
  #   identity_client_id = azurerm_user_assigned_identity.acr.client_id
  # }
  
  # Geo-replication (optional, for high availability)
  # georeplications {
  #   location                = "westus"
  #   zone_redundancy_enabled = true
  #   tags                    = local.common_tags
  # }
  
  tags = local.common_tags
}

# Diagnostic settings for ACR
resource "azurerm_monitor_diagnostic_setting" "acr" {
  name                       = "${local.resource_prefix}-acr-diagnostics"
  target_resource_id         = azurerm_container_registry.main.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id
  
  enabled_log {
    category = "ContainerRegistryRepositoryEvents"
  }
  
  enabled_log {
    category = "ContainerRegistryLoginEvents"
  }
  
  metric {
    category = "AllMetrics"
    enabled  = true
  }
}

# Outputs
output "acr_name" {
  value       = azurerm_container_registry.main.name
  description = "Container Registry name"
}

output "acr_login_server" {
  value       = azurerm_container_registry.main.login_server
  description = "Container Registry login server"
}

output "acr_id" {
  value       = azurerm_container_registry.main.id
  description = "Container Registry ID"
}
