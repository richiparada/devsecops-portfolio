# Monitoring and Observability

# Log Analytics Workspace
resource "azurerm_log_analytics_workspace" "main" {
  name                = "${local.resource_prefix}-logs"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "PerGB2018"
  retention_in_days   = 30  # Adjust based on compliance requirements
  
  tags = local.common_tags
}

# Application Insights
resource "azurerm_application_insights" "main" {
  name                = "${local.resource_prefix}-appinsights"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  workspace_id        = azurerm_log_analytics_workspace.main.id
  application_type    = "web"
  
  tags = local.common_tags
}

# Action Group for Alerts
resource "azurerm_monitor_action_group" "main" {
  name                = "${local.resource_prefix}-action-group"
  resource_group_name = azurerm_resource_group.main.name
  short_name          = "devsecops"
  
  # Email notification
  email_receiver {
    name                    = "admin-email"
    email_address           = "admin@example.com"  # Replace with actual email
    use_common_alert_schema = true
  }
  
  # Webhook notification (e.g., Slack, Teams)
  # webhook_receiver {
  #   name        = "slack-webhook"
  #   service_uri = var.slack_webhook_url
  # }
  
  tags = local.common_tags
}

# Alert: AKS Node CPU Usage
resource "azurerm_monitor_metric_alert" "aks_cpu" {
  name                = "${local.resource_prefix}-aks-cpu-alert"
  resource_group_name = azurerm_resource_group.main.name
  scopes              = [azurerm_kubernetes_cluster.main.id]
  description         = "Alert when AKS node CPU usage is high"
  severity            = 2
  frequency           = "PT5M"
  window_size         = "PT15M"
  
  criteria {
    metric_namespace = "Microsoft.ContainerService/managedClusters"
    metric_name      = "node_cpu_usage_percentage"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 80
  }
  
  action {
    action_group_id = azurerm_monitor_action_group.main.id
  }
  
  tags = local.common_tags
}

# Alert: AKS Node Memory Usage
resource "azurerm_monitor_metric_alert" "aks_memory" {
  name                = "${local.resource_prefix}-aks-memory-alert"
  resource_group_name = azurerm_resource_group.main.name
  scopes              = [azurerm_kubernetes_cluster.main.id]
  description         = "Alert when AKS node memory usage is high"
  severity            = 2
  frequency           = "PT5M"
  window_size         = "PT15M"
  
  criteria {
    metric_namespace = "Microsoft.ContainerService/managedClusters"
    metric_name      = "node_memory_working_set_percentage"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 80
  }
  
  action {
    action_group_id = azurerm_monitor_action_group.main.id
  }
  
  tags = local.common_tags
}

# Alert: Container Registry Storage Usage
resource "azurerm_monitor_metric_alert" "acr_storage" {
  name                = "${local.resource_prefix}-acr-storage-alert"
  resource_group_name = azurerm_resource_group.main.name
  scopes              = [azurerm_container_registry.main.id]
  description         = "Alert when ACR storage usage is high"
  severity            = 3
  frequency           = "PT1H"
  window_size         = "PT6H"
  
  criteria {
    metric_namespace = "Microsoft.ContainerRegistry/registries"
    metric_name      = "StorageUsed"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 107374182400  # 100 GB in bytes
  }
  
  action {
    action_group_id = azurerm_monitor_action_group.main.id
  }
  
  tags = local.common_tags
}

# Outputs
output "log_analytics_workspace_id" {
  value       = azurerm_log_analytics_workspace.main.id
  description = "Log Analytics Workspace ID"
}

output "log_analytics_workspace_name" {
  value       = azurerm_log_analytics_workspace.main.name
  description = "Log Analytics Workspace name"
}

output "application_insights_instrumentation_key" {
  value       = azurerm_application_insights.main.instrumentation_key
  description = "Application Insights instrumentation key"
  sensitive   = true
}

output "application_insights_connection_string" {
  value       = azurerm_application_insights.main.connection_string
  description = "Application Insights connection string"
  sensitive   = true
}
