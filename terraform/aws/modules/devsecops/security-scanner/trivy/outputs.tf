# Outputs do Módulo Trivy Security Scanner

output "trivy_dashboard_fqdn" {
  description = "FQDN do dashboard Trivy"
  value       = azurerm_container_group.trivy_dashboard.fqdn
}

output "trivy_dashboard_ip" {
  description = "IP público do dashboard Trivy"
  value       = azurerm_container_group.trivy_dashboard.ip_address
}

output "trivy_dashboard_url" {
  description = "URL completa do dashboard Trivy"
  value       = "http://${azurerm_container_group.trivy_dashboard.fqdn}:8080"
}

output "trivy_container_group_id" {
  description = "ID do Container Group do Trivy"
  value       = azurerm_container_group.trivy_dashboard.id
}

output "trivy_container_group_name" {
  description = "Nome do Container Group do Trivy"
  value       = azurerm_container_group.trivy_dashboard.name
}

output "trivy_image_url" {
  description = "URL da imagem Trivy no ACR"
  value       = "${var.acr_login_server}/trivy-dashboard:latest"
}

# Outputs para integração com Jenkins
output "jenkins_integration" {
  description = "Informações para integração com Jenkins"
  value = {
    trivy_server_url    = "http://${azurerm_container_group.trivy_dashboard.ip_address}:8080"
    scan_endpoint       = "http://${azurerm_container_group.trivy_dashboard.ip_address}:8080/scan"
    health_check_url    = "http://${azurerm_container_group.trivy_dashboard.ip_address}:8080/health"
  }
}