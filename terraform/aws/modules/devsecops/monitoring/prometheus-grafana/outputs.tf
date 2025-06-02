# Outputs do Módulo Grafana Monitoring

output "grafana_dashboard_fqdn" {
  description = "FQDN do dashboard Grafana"
  value       = azurerm_container_group.monitoring_stack.fqdn
}

output "grafana_dashboard_ip" {
  description = "IP público do dashboard Grafana"
  value       = azurerm_container_group.monitoring_stack.ip_address
}

output "grafana_dashboard_url" {
  description = "URL completa do dashboard Grafana"
  value       = "http://${azurerm_container_group.monitoring_stack.fqdn}:3000"
}

output "prometheus_url" {
  description = "URL do Prometheus"
  value       = "http://${azurerm_container_group.monitoring_stack.fqdn}:9090"
}

output "node_exporter_url" {
  description = "URL do Node Exporter"
  value       = "http://${azurerm_container_group.monitoring_stack.fqdn}:9100"
}

output "monitoring_container_group_id" {
  description = "ID do Container Group de monitoramento"
  value       = azurerm_container_group.monitoring_stack.id
}

output "monitoring_container_group_name" {
  description = "Nome do Container Group de monitoramento"
  value       = azurerm_container_group.monitoring_stack.name
}

output "monitoring_stack_image_url" {
  description = "URL da imagem do stack de monitoramento no ACR"
  value       = "${var.acr_login_server}/monitoring-stack:latest"
}

# Outputs para integração
output "monitoring_integration" {
  description = "Informações para integração de monitoramento"
  value = {
    grafana_url      = "http://${azurerm_container_group.monitoring_stack.ip_address}:3000"
    prometheus_url   = "http://${azurerm_container_group.monitoring_stack.ip_address}:9090"
    admin_user      = "admin"
    admin_password  = var.grafana_admin_password
    health_check    = "http://${azurerm_container_group.monitoring_stack.ip_address}:3000/api/health"
  }
}