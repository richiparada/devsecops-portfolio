# Security Configuration - Microsoft Defender for Cloud

# Enable Microsoft Defender for Containers
resource "azurerm_security_center_subscription_pricing" "containers" {
  tier          = "Standard"  # Free or Standard
  resource_type = "Containers"
}

# Enable Microsoft Defender for Container Registries
resource "azurerm_security_center_subscription_pricing" "container_registry" {
  tier          = "Standard"
  resource_type = "ContainerRegistry"
}

# Enable Microsoft Defender for Key Vaults
resource "azurerm_security_center_subscription_pricing" "keyvault" {
  tier          = "Standard"
  resource_type = "KeyVaults"
}

# Security Center Contact
resource "azurerm_security_center_contact" "main" {
  email               = "security@example.com"  # Replace with actual email
  phone               = "+1-555-0100"           # Replace with actual phone
  alert_notifications = true
  alerts_to_admins    = true
}



# Azure Policy Assignment: AKS should use Azure CNI
resource "azurerm_resource_policy_assignment" "aks_cni" {
  name                 = "aks-use-azure-cni"
  resource_id          = azurerm_kubernetes_cluster.main.id
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/9f061a12-e40d-4183-a00e-171812443373"
  
  parameters = jsonencode({
    effect = {
      value = "Audit"
    }
  })
}

# Azure Policy Assignment: Container images should be deployed from trusted registries only
resource "azurerm_resource_policy_assignment" "trusted_registries" {
  name                 = "aks-trusted-registries"
  resource_id          = azurerm_kubernetes_cluster.main.id
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/febd0533-8e55-448f-b837-bd0e06f16469"
  
  parameters = jsonencode({
    effect = {
      value = "Audit"
    }
    allowedContainerImagesRegex = {
      value = "^${azurerm_container_registry.main.login_server}/.+$"
    }
  })
}

# Azure Policy Assignment: Kubernetes clusters should not allow privileged containers
resource "azurerm_resource_policy_assignment" "no_privileged" {
  name                 = "aks-no-privileged-containers"
  resource_id          = azurerm_kubernetes_cluster.main.id
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/95edb821-ddaf-4404-9732-666045e056b4"
  
  parameters = jsonencode({
    effect = {
      value = "Deny"
    }
  })
}

# Azure Policy Assignment: Kubernetes clusters should disable automounting API credentials
resource "azurerm_resource_policy_assignment" "no_automount_token" {
  name                 = "aks-no-automount-token"
  resource_id          = azurerm_kubernetes_cluster.main.id
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/423dd1ba-798e-40e4-9c4d-b6902674b423"
  
  parameters = jsonencode({
    effect = {
      value = "Audit"
    }
  })
}

# Azure Policy Assignment: Container CPU and memory resource limits should not exceed the specified limits
resource "azurerm_resource_policy_assignment" "resource_limits" {
  name                 = "aks-resource-limits"
  resource_id          = azurerm_kubernetes_cluster.main.id
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/e345b6c3-24bd-4c93-9bbb-7e5e49a17b78"
  
  parameters = jsonencode({
    effect = {
      value = "Audit"
    }
    cpuLimit = {
      value = "2000m"
    }
    memoryLimit = {
      value = "4Gi"
    }
  })
}

# Outputs
output "defender_containers_enabled" {
  value       = azurerm_security_center_subscription_pricing.containers.tier == "Standard"
  description = "Whether Defender for Containers is enabled"
}

output "defender_acr_enabled" {
  value       = azurerm_security_center_subscription_pricing.container_registry.tier == "Standard"
  description = "Whether Defender for Container Registry is enabled"
}
