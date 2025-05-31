# VPC Module
module "network" {
  source = "./modules/network"

  project_name       = var.project_name
  environment        = var.environment
  vpc_cidr           = var.vpc_cidr
  public_subnet_1_cidr  = var.public_subnet_1_cidr
  public_subnet_2_cidr  = var.public_subnet_2_cidr
  private_subnet_1_cidr = var.private_subnet_1_cidr
  private_subnet_2_cidr = var.private_subnet_2_cidr
  availability_zone  = "${var.aws_region}a"
  tags               = local.common_tags
}

# Security Module
module "security" {
  source = "./modules/security"

  project_name = var.project_name
  environment  = var.environment
  vpc_id       = module.network.vpc_id
  allowed_ips  = var.allowed_ips
  jenkins_port = var.jenkins_port
  app_port     = var.app_port
  tags         = local.common_tags
}

# Compute Module
module "compute" {
  source = "./modules/compute"

  project_name       = var.project_name
  environment        = var.environment
  instance_type      = var.instance_type
  jenkins_key_name   = var.jenkins_key_name
  sonarqube_key_name = var.sonarqube_key_name
  subnet_id          = module.network.public_subnet_id
  jenkins_security_group_ids = [module.security.jenkins_security_group_id]
  sonarqube_security_group_ids = [module.security.sonarqube_security_group_id]
  volume_size        = var.volume_size
  tags               = local.common_tags
}

# Elastic IP Module
module "elastic_ip" {
  source = "./modules/elastic-ip"

  project_name = var.project_name
  environment  = var.environment
  jenkins_instance_id  = module.compute.jenkins_instance_id
  sonarqube_instance_id = module.compute.sonarqube_instance_id
  tags         = local.common_tags
}

# Módulo ECR (deve vir antes do ECS)
module "ecr" {
  source = "./modules/ecr"

  project_name = var.project_name
  environment  = var.environment
  tags         = local.common_tags
}

# Módulo ECS
# Onde está instalado o jenkins e o sonarqube atualmente
module "ecs" {
  source = "./modules/ecs"

  # Configurações básicas
  project_name = var.project_name
  environment  = var.environment
  tags         = local.common_tags
  aws_region   = var.aws_region

  # Configurações da task
  task_cpu    = var.task_cpu    # 0.25 vCPU
  task_memory = var.task_memory   # 0.5 GB
  app_port    = var.app_port
  
  # Número de instâncias
  desired_count = 1

  # Referências de outros módulos
  ecr_repository_url = module.ecr.repository_url
  vpc_id            = module.network.vpc_id
  private_subnet_ids = module.network.private_subnet_ids  # Se você tiver subnet privada
  public_subnet_ids  = module.network.public_subnet_ids
}

# module "jenkins_pipeline_vm" {
#   source                = "./modules/devsecops/pipeline/jenkins"
#   resource_group_name   = module.resource_group.name
#   location              = var.location
#   prefix                = "${var.prefix}-jenkins"
#   subnet_id             = module.networking.app_subnet_id
#   vm_size               = var.jenkins_vm_size
#   admin_username        = var.admin_username
#   admin_password        = var.admin_password
#   disable_password_auth = false
#   admin_ssh_key_data    = tls_private_key.ssh_key.public_key_openssh
#   public_ip_name        = "${var.prefix}-jenkins-pip"
#   private_ip_address    = var.jenkins_private_ip
#   custom_data           = base64encode(join("\n", [
#     file("${path.module}/scripts/install-docker.sh"),
#     file("${path.module}/scripts/setup-jenkins-docker.sh")
#   ]))
#   tags                  = var.tags
# }

# # Compute (VM para SonarQube)
# module "sonarqube_qa_vm" {
#   source                = "./modules/devsecops/quality-assurance/sonarqube"
#   resource_group_name   = module.resource_group.name
#   location              = var.location
#   prefix                = "${var.prefix}-sonarqube"
#   subnet_id             = module.networking.app_subnet_id
#   vm_size               = var.sonarqube_vm_size
#   admin_username        = var.admin_username
#   admin_password        = var.admin_password
#   disable_password_auth = false
#   admin_ssh_key_data    = tls_private_key.ssh_key.public_key_openssh
#   public_ip_name        = "${var.prefix}-sonarqube-pip"
#   private_ip_address    = var.sonarqube_private_ip
#   custom_data           = base64encode(join("\n", [
#     file("${path.module}/scripts/install-docker.sh"),
#     file("${path.module}/scripts/setup-sonarqube-docker.sh")
#   ]))
#   tags                  = var.tags
# }

# # Trivy Security Scanner
# module "trivy_security_scanner" {
#   source              = "./modules/devsecops/security-scanner/trivy"
#   resource_group_name = module.resource_group.name
#   location            = var.location
#   prefix              = var.prefix
  
#   # Integração com ACR
#   acr_login_server    = module.container_registry.login_server
#   acr_admin_username  = module.container_registry.admin_username
#   acr_admin_password  = module.container_registry.admin_password
#   acr_dependency      = module.container_registry
  
#   tags = merge(var.tags, {
#     Module      = "DevSecOps"
#     Component   = "Security-Scanner"
#     Tool        = "Trivy"
#     Environment = var.environment
#   })
# }

# # OWASP ZAP Proxy Security Testing
# module "owasp_zap_testing" {
#   source              = "./modules/devsecops/proxy-security/owasp-zap"
#   resource_group_name = module.resource_group.name
#   location            = var.location
#   prefix              = var.prefix
  
#   # Integração com ACR
#   acr_login_server    = module.container_registry.login_server
#   acr_admin_username  = module.container_registry.admin_username
#   acr_admin_password  = module.container_registry.admin_password
#   acr_dependency      = module.container_registry
  
#   tags = merge(var.tags, {
#     Module      = "DevSecOps"
#     Component   = "Quality-Assurance"
#     Tool        = "OWASP-ZAP"
#     Environment = var.environment
#   })
# }

# # # Grafana Monitoring Stack
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