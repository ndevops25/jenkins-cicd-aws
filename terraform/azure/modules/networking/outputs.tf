output "vnet_id" {
  description = "O ID da rede virtual"
  value       = azurerm_virtual_network.vnet.id
}

output "vnet_name" {
  description = "O nome da rede virtual"
  value       = azurerm_virtual_network.vnet.name
}

output "app_subnet_id" {
  description = "O ID da subnet de aplicativo"
  value       = azurerm_subnet.app_subnet.id
}

output "container_subnet_id" {
  description = "O ID da subnet de container"
  value       = azurerm_subnet.container_subnet.id
}

output "gateway_subnet_id" {
  description = "O ID da subnet de gateway"
  value       = azurerm_subnet.gateway_subnet.id
}

output "app_nsg_id" {
  description = "O ID do grupo de segurança de rede do aplicativo"
  value       = azurerm_network_security_group.app_nsg.id
}