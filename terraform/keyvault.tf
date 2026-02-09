# Azure Key Vault for Secrets Management

# Get current client for Key Vault access
data "azurerm_client_config" "current" {}

# Key Vault
resource "azurerm_key_vault" "main" {
  name                        = "${var.project_name}-${var.environment}-kv"
  location                    = azurerm_resource_group.main.location
  resource_group_name         = azurerm_resource_group.main.name
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  sku_name                    = "premium"  # Premium for HSM-backed keys
  
  # Security: Enable purge protection
  purge_protection_enabled    = true
  
  # Security: Enable soft delete
  soft_delete_retention_days  = 7
  
  # Security: Disable public network access (optional, can complicate access)
  # public_network_access_enabled = false
  
  # Network ACLs
  network_acls {
    default_action = "Allow"  # Change to "Deny" in production
    bypass         = "AzureServices"
    
    # Allow from AKS subnet
    virtual_network_subnet_ids = [
      azurerm_subnet.aks.id,
      azurerm_subnet.jenkins.id
    ]
  }
  
  # Enable RBAC authorization (recommended over access policies)
  enable_rbac_authorization = true
  
  tags = local.common_tags
}

# Role assignment: Current user as Key Vault Administrator (for initial setup)
resource "azurerm_role_assignment" "kv_admin" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = data.azurerm_client_config.current.object_id
}

# Role assignment: AKS managed identity to read secrets
resource "azurerm_role_assignment" "aks_kv_secrets" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_kubernetes_cluster.main.key_vault_secrets_provider[0].secret_identity[0].object_id
}

# Example secrets (create these manually or via separate process)
# DO NOT hardcode sensitive values in Terraform!

# resource "azurerm_key_vault_secret" "db_connection_string" {
#   name         = "db-connection-string"
#   value        = var.db_connection_string  # Pass via variable, never hardcode
#   key_vault_id = azurerm_key_vault.main.id
#   
#   depends_on = [azurerm_role_assignment.kv_admin]
# }

# resource "azurerm_key_vault_secret" "api_key" {
#   name         = "api-key"
#   value        = var.api_key
#   key_vault_id = azurerm_key_vault.main.id
#   
#   depends_on = [azurerm_role_assignment.kv_admin]
# }

# Diagnostic settings for Key Vault
resource "azurerm_monitor_diagnostic_setting" "keyvault" {
  name                       = "${local.resource_prefix}-kv-diagnostics"
  target_resource_id         = azurerm_key_vault.main.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id
  
  enabled_log {
    category = "AuditEvent"
  }
  
  enabled_log {
    category = "AzurePolicyEvaluationDetails"
  }
  
  metric {
    category = "AllMetrics"
    enabled  = true
  }
}

# Outputs
output "key_vault_name" {
  value       = azurerm_key_vault.main.name
  description = "Key Vault name"
}

output "key_vault_id" {
  value       = azurerm_key_vault.main.id
  description = "Key Vault ID"
}

output "key_vault_uri" {
  value       = azurerm_key_vault.main.vault_uri
  description = "Key Vault URI"
}
