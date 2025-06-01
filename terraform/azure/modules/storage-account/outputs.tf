output "id" {
  description = "O ID da conta de armazenamento"
  value       = azurerm_storage_account.sa.id
}

output "name" {
  description = "O nome da conta de armazenamento"
  value       = azurerm_storage_account.sa.name
}

output "primary_access_key" {
  description = "A chave de acesso primária da conta de armazenamento"
  value       = azurerm_storage_account.sa.primary_access_key
  sensitive   = true
}

output "container_name" {
  description = "O nome do container criado"
  value       = azurerm_storage_container.container.name
}