output "name" {
  description = "O nome do grupo de recursos"
  value       = azurerm_resource_group.rg.name
}

output "id" {
  description = "O ID do grupo de recursos"
  value       = azurerm_resource_group.rg.id
}

output "location" {
  description = "A localização do grupo de recursos"
  value       = azurerm_resource_group.rg.location
}