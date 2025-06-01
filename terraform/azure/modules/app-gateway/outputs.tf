output "id" {
  description = "O ID do Application Gateway"
  value       = azurerm_application_gateway.appgw.id
}

output "name" {
  description = "O nome do Application Gateway"
  value       = azurerm_application_gateway.appgw.name
}

output "public_ip_address" {
  description = "O endereço IP público do Application Gateway"
  value       = azurerm_public_ip.pip.ip_address
}

output "fqdn" {
  description = "O FQDN do IP público do Application Gateway"
  value       = azurerm_public_ip.pip.fqdn
}