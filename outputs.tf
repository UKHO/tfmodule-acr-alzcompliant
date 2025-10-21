# ============================================
# Azure Container Registry Outputs
# ============================================

output "id" {
  description = "The ID of the Container Registry."
  value       = azurerm_container_registry.acr.id
}

output "name" {
  description = "The name of the Container Registry."
  value       = azurerm_container_registry.acr.name
}

output "login_server" {
  description = "The URL that can be used to log into the Container Registry."
  value       = azurerm_container_registry.acr.login_server
}

output "admin_username" {
  description = "The Username associated with the Container Registry Admin account (if enabled)."
  value       = azurerm_container_registry.acr.admin_username
  sensitive   = true
}

output "admin_password" {
  description = "The Password associated with the Container Registry Admin account (if enabled)."
  value       = azurerm_container_registry.acr.admin_password
  sensitive   = true
}

output "identity_principal_id" {
  description = "The Principal ID of the System Assigned Managed Identity."
  value       = try(azurerm_container_registry.acr.identity[0].principal_id, null)
}

output "identity_tenant_id" {
  description = "The Tenant ID of the System Assigned Managed Identity."
  value       = try(azurerm_container_registry.acr.identity[0].tenant_id, null)
}

output "data_endpoint_host_names" {
  description = "A set of data endpoint hostnames associated with the container registry (if data endpoints are enabled)."
  value       = azurerm_container_registry.acr.data_endpoint_enabled ? azurerm_container_registry.acr.data_endpoint_host_names : []
}

output "private_endpoint_id" {
  description = "The ID of the private endpoint (if created)."
  value       = var.create_private_endpoint ? azurerm_private_endpoint.acr[0].id : null
}

output "private_endpoint_ip_address" {
  description = "The private IP address of the private endpoint (if created)."
  value       = var.create_private_endpoint ? azurerm_private_endpoint.acr[0].private_service_connection[0].private_ip_address : null
}
