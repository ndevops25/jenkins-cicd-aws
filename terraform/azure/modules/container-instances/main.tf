# Azure Container Instances usando imagem do ACR
resource "azurerm_container_group" "python_app" {
  name                = "${var.prefix}-python-app"
  location            = var.location
  resource_group_name = var.resource_group_name
  ip_address_type     = "Public"
  dns_name_label      = "${var.prefix}-python-app"
  os_type             = "Linux"
  restart_policy      = "Always"
  
  depends_on = [null_resource.build_and_push_image]
  
  # Container usando imagem do ACR
  container {
    name   = "python-app"
    image  = "${var.acr_login_server}/python-app:latest"
    cpu    = "0.5"
    memory = "1.0"

    ports {
      port     = 8000
      protocol = "TCP"
    }

    environment_variables = {
      "PYTHONUNBUFFERED" = "1"
      "PORT" = "8000"
      "ENV"  = "production"
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