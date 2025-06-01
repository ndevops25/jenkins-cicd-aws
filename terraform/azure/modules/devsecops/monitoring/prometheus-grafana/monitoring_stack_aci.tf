# Grafana Monitoring Dashboard Module
# Implementa Grafana com Prometheus integration para observabilidade completa

# Container Instance para Grafana + Prometheus
resource "azurerm_container_group" "monitoring_stack" {
  name                = "${var.prefix}-monitoring"
  location            = var.location
  resource_group_name = var.resource_group_name
  ip_address_type     = "Public"
  dns_name_label      = "${var.prefix}-monitoring"
  os_type             = "Linux"
  restart_policy      = "Always"
  
  depends_on = [null_resource.build_monitoring_stack]
  
  container {
    name   = "monitoring-stack"
    image  = "${var.acr_login_server}/monitoring-stack:latest"
    cpu    = "2.0"    # Monitoring stack precisa de recursos
    memory = "4.0"    # Memória adequada para Grafana + Prometheus
    
    # Porta do Grafana
    ports {
      port     = 3000
      protocol = "TCP"
    }
    
    # Porta do Prometheus
    ports {
      port     = 9090
      protocol = "TCP"
    }
    
    # Porta do Node Exporter
    ports {
      port     = 9100
      protocol = "TCP"
    }
    
    environment_variables = {
      "GF_SECURITY_ADMIN_PASSWORD" = var.grafana_admin_password
      "GF_USERS_ALLOW_SIGN_UP"    = "false"
    }
  }
  
  # Credenciais do ACR
  image_registry_credential {
    server   = var.acr_login_server
    username = var.acr_admin_username
    password = var.acr_admin_password
  }
  
  tags = var.tags
}