# Trivy Security Scanner Module
# Implementa Trivy Server com dashboard web para visualização de vulnerabilidades

# Container Instance para o Trivy Dashboard
resource "azurerm_container_group" "trivy_dashboard" {
  name                = "${var.prefix}-trivy-dashboard"
  location            = var.location
  resource_group_name = var.resource_group_name
  ip_address_type     = "Public"
  dns_name_label      = "${var.prefix}-trivy"
  os_type             = "Linux"
  restart_policy      = "Always"
  
  depends_on = [null_resource.build_trivy_image]
  
  container {
    name   = "trivy-dashboard"
    image  = "${var.acr_login_server}/trivy-dashboard:latest"
    cpu    = "1.0"    # Trivy precisa de mais CPU para scanning
    memory = "2.0"    # Trivy precisa de mais memória
    
    ports {
      port     = 8080
      protocol = "TCP"
    }
    
    environment_variables = {
      "PYTHONUNBUFFERED" = "1"
      "TRIVY_CACHE_DIR"  = "/tmp/trivy-cache"
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