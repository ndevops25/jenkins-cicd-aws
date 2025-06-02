# OWASP ZAP Security Testing Module
# Implementa OWASP ZAP com dashboard web para testes de segurança de aplicações web

# Container Instance para OWASP ZAP
resource "azurerm_container_group" "owasp_zap" {
  name                = "${var.prefix}-owasp-zap"
  location            = var.location
  resource_group_name = var.resource_group_name
  ip_address_type     = "Public"
  dns_name_label      = "${var.prefix}-owasp-zap"
  os_type             = "Linux"
  restart_policy      = "Always"
  
  depends_on = [null_resource.build_zap_image]
  
  container {
    name   = "owasp-zap-dashboard"
    image  = "${var.acr_login_server}/owasp-zap-dashboard:latest"
    cpu    = "2.0"    # ZAP precisa de mais CPU
    memory = "4.0"    # ZAP precisa de mais memória
    
    ports {
      port     = 8080
      protocol = "TCP"
    }
    
    ports {
      port     = 8090
      protocol = "TCP"
    }
    
    environment_variables = {
      "PYTHONUNBUFFERED" = "1"
      "ZAP_PORT"         = "8090"
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