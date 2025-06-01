output "vm_id" {
  description = "O ID da VM criada"
  value       = azurerm_linux_virtual_machine.vm.id
}

output "vm_name" {
  description = "O nome da VM criada"
  value       = azurerm_linux_virtual_machine.vm.name
}

output "public_ip_address" {
  description = "O endereço IP público da VM"
  value       = azurerm_public_ip.pip.ip_address
}

output "public_ip_fqdn" {
  description = "O FQDN do IP público"
  value       = azurerm_public_ip.pip.fqdn
}

output "private_ip_address" {
  description = "O endereço IP privado da VM"
  value       = azurerm_network_interface.nic.ip_configuration[0].private_ip_address
}