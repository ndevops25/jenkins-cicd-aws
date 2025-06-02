# Outputs do Módulo OWASP ZAP Security Testing

output "zap_dashboard_fqdn" {
  description = "FQDN do dashboard OWASP ZAP"
  value       = azurerm_container_group.owasp_zap.fqdn
}

output "zap_dashboard_ip" {
  description = "IP público do dashboard OWASP ZAP"
  value       = azurerm_container_group.owasp_zap.ip_address
}

output "zap_dashboard_url" {
  description = "URL completa do dashboard OWASP ZAP"
  value       = "http://${azurerm_container_group.owasp_zap.fqdn}:8080"
}

output "zap_api_url" {
  description = "URL da API do OWASP ZAP"
  value       = "http://${azurerm_container_group.owasp_zap.fqdn}:8090"
}

output "zap_container_group_id" {
  description = "ID do Container Group do OWASP ZAP"
  value       = azurerm_container_group.owasp_zap.id
}

output "zap_container_group_name" {
  description = "Nome do Container Group do OWASP ZAP"
  value       = azurerm_container_group.owasp_zap.name
}

output "zap_image_url" {
  description = "URL da imagem OWASP ZAP no ACR"
  value       = "${var.acr_login_server}/owasp-zap-dashboard:latest"
}

# Outputs para integração com Jenkins
output "jenkins_integration" {
  description = "Informações para integração com Jenkins"
  value = {
    zap_dashboard_url = "http://${azurerm_container_group.owasp_zap.ip_address}:8080"
    zap_api_url       = "http://${azurerm_container_group.owasp_zap.ip_address}:8090"
    scan_endpoint     = "http://${azurerm_container_group.owasp_zap.ip_address}:8080/scan"
    health_check_url  = "http://${azurerm_container_group.owasp_zap.ip_address}:8080/health"
  }
}