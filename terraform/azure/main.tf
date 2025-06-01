# Gerar par de chaves SSH automaticamente
resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Salvar chaves localmente
resource "local_file" "private_key" {
  content         = tls_private_key.ssh_key.private_key_pem
  filename        = "${path.module}/ssh-keys/id_rsa"
  file_permission = "0600"
}

resource "local_file" "public_key" {
  content         = tls_private_key.ssh_key.public_key_openssh
  filename        = "${path.module}/ssh-keys/id_rsa.pub"
  file_permission = "0644"
}

# Resource Group
module "resource_group" {
  source   = "./modules/resource-group"
  name     = "${var.prefix}-rg"
  location = var.location
  tags     = var.tags
}

# Storage Account
module "storage_account" {
  source                   = "./modules/storage-account"
  resource_group_name      = module.resource_group.name
  location                 = var.location
  prefix                   = var.prefix
  account_tier             = "Standard"
  account_replication_type = "LRS"
  container_name           = "tfstate"
  tags                     = var.tags
}

# Networking com subnet adicional para AKS
module "networking" {
  source              = "./modules/networking"
  resource_group_name = module.resource_group.name
  location            = var.location
  prefix              = var.prefix
  address_space       = var.address_space
  tags                = var.tags
}

# Container Registry (ACR)
module "container_registry" {
  source              = "./modules/container-registry"
  resource_group_name = module.resource_group.name
  location            = var.location
  prefix              = var.prefix
  sku                 = "Standard"
  admin_enabled       = true
  tags                = var.tags
}

# Compute (VM para Jenkins)
module "jenkins_pipeline_vm" {
  source                = "./modules/devsecops/pipeline/jenkins"
  resource_group_name   = module.resource_group.name
  location              = var.location
  prefix                = "${var.prefix}-jenkins"
  subnet_id             = module.networking.app_subnet_id
  vm_size               = var.jenkins_vm_size
  admin_username        = var.admin_username
  admin_password        = var.admin_password
  disable_password_auth = false
  admin_ssh_key_data    = tls_private_key.ssh_key.public_key_openssh
  public_ip_name        = "${var.prefix}-jenkins-pip"
  private_ip_address    = var.jenkins_private_ip
  custom_data           = base64encode(join("\n", [
    file("${path.module}/scripts/install-docker.sh"),
    file("${path.module}/scripts/setup-jenkins-docker.sh")
  ]))
  tags                  = var.tags
}

# Compute (VM para SonarQube)
module "sonarqube_qa_vm" {
  source                = "./modules/devsecops/quality-assurance/sonarqube"
  resource_group_name   = module.resource_group.name
  location              = var.location
  prefix                = "${var.prefix}-sonarqube"
  subnet_id             = module.networking.app_subnet_id
  vm_size               = var.sonarqube_vm_size
  admin_username        = var.admin_username
  admin_password        = var.admin_password
  disable_password_auth = false
  admin_ssh_key_data    = tls_private_key.ssh_key.public_key_openssh
  public_ip_name        = "${var.prefix}-sonarqube-pip"
  private_ip_address    = var.sonarqube_private_ip
  custom_data           = base64encode(join("\n", [
    file("${path.module}/scripts/install-docker.sh"),
    file("${path.module}/scripts/setup-sonarqube-docker.sh")
  ]))
  tags                  = var.tags
}

# Trivy Security Scanner
module "trivy_security_scanner" {
  source              = "./modules/devsecops/security-scanner/trivy"
  resource_group_name = module.resource_group.name
  location            = var.location
  prefix              = var.prefix
  
  # Integração com ACR
  acr_login_server    = module.container_registry.login_server
  acr_admin_username  = module.container_registry.admin_username
  acr_admin_password  = module.container_registry.admin_password
  acr_dependency      = module.container_registry
  
  tags = merge(var.tags, {
    Module      = "DevSecOps"
    Component   = "Security-Scanner"
    Tool        = "Trivy"
    Environment = var.environment
  })
}

# OWASP ZAP Proxy Security Testing
module "owasp_zap_testing" {
  source              = "./modules/devsecops/proxy-security/owasp-zap"
  resource_group_name = module.resource_group.name
  location            = var.location
  prefix              = var.prefix
  
  # Integração com ACR
  acr_login_server    = module.container_registry.login_server
  acr_admin_username  = module.container_registry.admin_username
  acr_admin_password  = module.container_registry.admin_password
  acr_dependency      = module.container_registry
  
  tags = merge(var.tags, {
    Module      = "DevSecOps"
    Component   = "Quality-Assurance"
    Tool        = "OWASP-ZAP"
    Environment = var.environment
  })
}

# # Grafana Monitoring Stack
# module "grafana_monitoring" {
#   source              = "./modules/devsecops/monitoring/prometheus-grafana"
#   resource_group_name = module.resource_group.name
#   location            = var.location
#   prefix              = var.prefix
  
#   # Integração com ACR
#   acr_login_server    = module.container_registry.login_server
#   acr_admin_username  = module.container_registry.admin_username
#   acr_admin_password  = module.container_registry.admin_password
#   acr_dependency      = module.container_registry
  
#   # Configurações específicas
#   grafana_admin_password = "GrafanaAdmin123!"  # Mude para uma senha segura
  
#   # Integração com outros serviços
#   trivy_dashboard_ip = module.trivy_security_scanner.trivy_dashboard_ip
#   zap_dashboard_ip   = module.owasp_zap_testing.zap_dashboard_ip
#   jenkins_vm_ip      = module.jenkins_pipeline_vm.private_ip_address
  
#   tags = merge(var.tags, {
#     Module      = "DevSecOps"
#     Component   = "Monitoring"
#     Tool        = "Grafana"
#     Environment = var.environment
#   })
# }

# ACI com imagem do ACR
module "container_instances" {
  source              = "./modules/container-instances"
  resource_group_name = module.resource_group.name
  location            = var.location
  prefix              = var.prefix
  
  # Integração com ACR
  acr_login_server    = module.container_registry.login_server
  acr_admin_username  = module.container_registry.admin_username
  acr_admin_password  = module.container_registry.admin_password
  acr_dependency      = module.container_registry  # Garantir ordem
  
  tags = var.tags
}

# Application Gateway apontando para ACI
module "app_gateway" {
  source                  = "./modules/app-gateway"
  resource_group_name     = module.resource_group.name
  location                = var.location
  prefix                  = var.prefix
  subnet_id               = module.networking.gateway_subnet_id
  backend_address_pool_ip = module.container_instances.app_ip_address  # IP do ACI
  backend_http_port       = var.python_app_port
  sku_tier                = "Standard_v2"
  sku_size                = "Standard_v2"
  capacity                = 2
  tags                    = var.tags
}