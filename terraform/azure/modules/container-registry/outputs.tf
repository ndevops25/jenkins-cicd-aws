output "id" {
  description = "O ID do Azure Container Registry"
  value       = azurerm_container_registry.acr.id
}

output "name" {
  description = "O nome do Azure Container Registry"
  value       = azurerm_container_registry.acr.name
}

output "login_server" {
  description = "O URL do servidor de login do Azure Container Registry"
  value       = azurerm_container_registry.acr.login_server
}

output "admin_username" {
  description = "O nome de usuário administrador do Azure Container Registry"
  value       = azurerm_container_registry.acr.admin_username
}

output "admin_password" {
  description = "A senha do administrador do Azure Container Registry"
  value       = azurerm_container_registry.acr.admin_password
  sensitive   = true
}