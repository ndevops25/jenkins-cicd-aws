# ========================================
# OUTPUTS PRINCIPAIS - INFRAESTRUTURA
# ========================================

output "resource_group_name" {
  description = "Nome do grupo de recursos"
  value       = module.resource_group.name
}

output "location" {
  description = "Localização dos recursos"
  value       = var.location
}

# ========================================
# OUTPUTS - MÁQUINAS VIRTUAIS
# ========================================

output "jenkins_pipeline_vm_public_ip" {
  description = "Endereço IP público da VM Jenkins"
  value       = module.jenkins_pipeline_vm.public_ip_address
}

output "jenkins_pipeline_vm_private_ip" {
  description = "Endereço IP privado da VM Jenkins"
  value       = module.jenkins_pipeline_vm.private_ip_address
}

output "sonarqube_qa_vm_public_ip" {
  description = "Endereço IP público da VM SonarQube"
  value       = module.sonarqube_qa_vm.public_ip_address
}

output "sonarqube_qa_vm_private_ip" {
  description = "Endereço IP privado da VM SonarQube"
  value       = module.sonarqube_qa_vm.private_ip_address
}

# ========================================
# OUTPUTS - CONTAINER REGISTRY (ACR)
# ========================================

output "container_registry_login_server" {
  description = "URL do servidor de login do Azure Container Registry"
  value       = module.container_registry.login_server
}

output "container_registry_admin_username" {
  description = "Nome de usuário admin do Container Registry"
  value       = module.container_registry.admin_username
}

output "container_registry_admin_password" {
  description = "Senha admin do Container Registry"
  value       = module.container_registry.admin_password
  sensitive   = true
}

output "container_registry_id" {
  description = "ID do Azure Container Registry"
  value       = module.container_registry.id
}

# ========================================
# OUTPUTS - AZURE CONTAINER INSTANCES (ACI)
# ========================================

output "python_app_fqdn" {
  description = "FQDN da aplicação Python no ACI"
  value       = module.container_instances.app_fqdn
}

output "python_app_ip_address" {
  description = "IP público da aplicação Python"
  value       = module.container_instances.app_ip_address
}

output "python_app_url" {
  description = "URL completa para acessar a aplicação Python"
  value       = module.container_instances.app_url
}

output "python_app_container_group_id" {
  description = "ID do Container Group da aplicação Python"
  value       = module.container_instances.container_group_id
}

# ========================================
# OUTPUTS - APPLICATION GATEWAY
# ========================================

output "app_gateway_public_ip" {
  description = "Endereço IP público do Application Gateway"
  value       = module.app_gateway.public_ip_address
}

output "app_gateway_fqdn" {
  description = "FQDN do Application Gateway"
  value       = module.app_gateway.fqdn
}

output "app_gateway_url" {
  description = "URL do Application Gateway (entrada principal)"
  value       = "http://${module.app_gateway.fqdn}"
}

# ========================================
# OUTPUTS - REDE
# ========================================

output "virtual_network_name" {
  description = "Nome da rede virtual"
  value       = module.networking.vnet_name
}

output "virtual_network_id" {
  description = "ID da rede virtual"
  value       = module.networking.vnet_id
}

output "subnets" {
  description = "IDs das subnets criadas"
  value = {
    app_subnet       = module.networking.app_subnet_id
    container_subnet = module.networking.container_subnet_id
    gateway_subnet   = module.networking.gateway_subnet_id
  }
}

# ========================================
# OUTPUTS - SSH E ACESSO
# ========================================

output "ssh_private_key" {
  description = "Chave SSH privada para acesso às VMs"
  value       = tls_private_key.ssh_key.private_key_pem
  sensitive   = true
}

output "ssh_public_key" {
  description = "Chave SSH pública"
  value       = tls_private_key.ssh_key.public_key_openssh
}

output "ssh_connection_commands" {
  description = "Comandos para conectar às VMs via SSH"
  value = {
    jenkins   = "ssh -i ssh-keys/id_rsa ${var.admin_username}@${module.jenkins_pipeline_vm.public_ip_address}"
    sonarqube = "ssh -i ssh-keys/id_rsa ${var.admin_username}@${module.sonarqube_qa_vm.public_ip_address}"
  }
}

# ========================================
# OUTPUTS - INFORMAÇÕES DE DEBUG
# ========================================

output "debug_info" {
  description = "Informações para debug e troubleshooting"
  value = {
    terraform_workspace = terraform.workspace
    resource_prefix     = var.prefix
    environment        = var.tags
  }
}

# ========================================
# OUTPUTS - URLS DE ACESSO
# ========================================
output "access_urls" {
  description = "URLs para acessar os serviços"
  value = {
    jenkins_vm         = "http://${module.jenkins_pipeline_vm.public_ip_address}:8080"
    sonarqube_vm       = "http://${module.sonarqube_qa_vm.public_ip_address}:9000"
    python_app_direct  = module.container_instances.app_url
    python_app_gateway = "http://${module.app_gateway.fqdn}"
    container_registry = "https://${module.container_registry.login_server}"
    trivy_dashboard    = module.trivy_security_scanner.trivy_dashboard_url  # NOVO!
  }
}

# ========================================
# OUTPUTS - JENKINS INTEGRATION
# ========================================
output "jenkins_environment_variables" {
  description = "Variáveis de ambiente para configurar no Jenkins"
  value = {
    ACR_LOGIN_SERVER = module.container_registry.login_server
    ACR_USERNAME     = module.container_registry.admin_username
    RESOURCE_GROUP   = module.resource_group.name
    CONTAINER_GROUP  = module.container_instances.container_group_name
    APP_URL         = module.container_instances.app_url
    
    # Integração com Trivy - NOVO!
    TRIVY_SERVER_URL = module.trivy_security_scanner.jenkins_integration.trivy_server_url
    TRIVY_SCAN_ENDPOINT = module.trivy_security_scanner.jenkins_integration.scan_endpoint
    TRIVY_HEALTH_URL = module.trivy_security_scanner.jenkins_integration.health_check_url
  }
}

# ========================================
# OUTPUTS - COMANDOS ÚTEIS
# ========================================
output "useful_commands" {
  description = "Comandos úteis para gerenciar a infraestrutura"
  value = {
    # ACR Commands
    acr_login = "az acr login --name ${split(".", module.container_registry.login_server)[0]}"
    acr_list_images = "az acr repository list --name ${split(".", module.container_registry.login_server)[0]}"
    
    # ACI Commands
    aci_logs = "az container logs --resource-group ${module.resource_group.name} --name ${module.container_instances.container_group_name}"
    aci_restart = "az container restart --resource-group ${module.resource_group.name} --name ${module.container_instances.container_group_name}"
    aci_status = "az container show --resource-group ${module.resource_group.name} --name ${module.container_instances.container_group_name} --query instanceView.state"
    
    # Trivy Commands - NOVO!
    trivy_logs = "az container logs --resource-group ${module.resource_group.name} --name ${module.trivy_security_scanner.trivy_container_group_name}"
    trivy_restart = "az container restart --resource-group ${module.resource_group.name} --name ${module.trivy_security_scanner.trivy_container_group_name}"
    trivy_status = "az container show --resource-group ${module.resource_group.name} --name ${module.trivy_security_scanner.trivy_container_group_name} --query instanceView.state"
    
    # Docker Commands
    docker_build = "docker build -t ${module.container_registry.login_server}/python-app:latest ."
    docker_push = "docker push ${module.container_registry.login_server}/python-app:latest"
    
    # Security Commands - NOVO!
    scan_image = "curl -X POST ${module.trivy_security_scanner.trivy_dashboard_url}/scan -H 'Content-Type: application/json' -d '{\"image\": \"your-image:tag\"}'"
  }
}

output "jenkins_secrets" {
  description = "Secrets que devem ser configurados no Jenkins"
  value = {
    ACR_PASSWORD = "Configure este secret no Jenkins com o valor da senha do ACR"
  }
  sensitive = false
}


# ========================================
# OUTPUTS - DEVSECOPS SECURITY SCANNER
# ========================================

output "trivy_dashboard_fqdn" {
  description = "FQDN do dashboard Trivy"
  value       = module.trivy_security_scanner.trivy_dashboard_fqdn
}

output "trivy_dashboard_ip" {
  description = "IP público do dashboard Trivy"
  value       = module.trivy_security_scanner.trivy_dashboard_ip
}

output "trivy_dashboard_url" {
  description = "URL completa do dashboard Trivy"
  value       = module.trivy_security_scanner.trivy_dashboard_url
}

# ========================================
# OUTPUTS - GRAFANA MONITORING STACK
# ========================================

# output "grafana_dashboard_fqdn" {
#   description = "FQDN do dashboard Grafana"
#   value       = module.grafana_monitoring.grafana_dashboard_fqdn
# }

# output "grafana_dashboard_ip" {
#   description = "IP público do dashboard Grafana"
#   value       = module.grafana_monitoring.grafana_dashboard_ip
# }

# output "grafana_dashboard_url" {
#   description = "URL completa do dashboard Grafana"
#   value       = module.grafana_monitoring.grafana_dashboard_url
# }

# output "prometheus_url" {
#   description = "URL do Prometheus"
#   value       = module.grafana_monitoring.prometheus_url
# }

# output "monitoring_container_group_id" {
#   description = "ID do Container Group de monitoramento"
#   value       = module.grafana_monitoring.monitoring_container_group_id
# }

# ========================================
# OUTPUTS - OWASP ZAP SECURITY TESTING
# ========================================

output "zap_dashboard_fqdn" {
  description = "FQDN do dashboard OWASP ZAP"
  value       = module.owasp_zap_testing.zap_dashboard_fqdn
}

output "zap_dashboard_ip" {
  description = "IP público do dashboard OWASP ZAP"
  value       = module.owasp_zap_testing.zap_dashboard_ip
}

output "zap_dashboard_url" {
  description = "URL completa do dashboard OWASP ZAP"
  value       = module.owasp_zap_testing.zap_dashboard_url
}

output "zap_api_url" {
  description = "URL da API do OWASP ZAP"
  value       = module.owasp_zap_testing.zap_api_url
}

output "zap_container_group_id" {
  description = "ID do Container Group do OWASP ZAP"
  value       = module.owasp_zap_testing.zap_container_group_id
}

# ========================================
# OUTPUTS - DEVSECOPS DASHBOARD INFO
# ========================================
output "devsecops_dashboard_info" {
  description = "Informações dos dashboards de DevSecOps"
  value = {
    security = {
      trivy_dashboard_url = module.trivy_security_scanner.trivy_dashboard_url
      trivy_image_url     = module.trivy_security_scanner.trivy_image_url
      scan_endpoint       = "${module.trivy_security_scanner.trivy_dashboard_url}/scan"
      integration_guide   = "Use a URL ${module.trivy_security_scanner.trivy_dashboard_url} para acessar o dashboard de segurança Trivy"
      zap_dashboard_url   = module.owasp_zap_testing.zap_dashboard_url
      zap_api_url         = module.owasp_zap_testing.zap_api_url
    }
    
    # monitoring = {
    #   grafana_url    = module.grafana_monitoring.grafana_dashboard_url
    #   prometheus_url = module.grafana_monitoring.prometheus_url
    # }
    
    quality = {
      sonarqube_url = "http://${module.sonarqube_qa_vm.public_ip_address}:9000"
    }
    
    cicd = {
      jenkins_url = "http://${module.jenkins_pipeline_vm.public_ip_address}:8080"
    }
    
    jenkins_integration = {
      trivy_environment_variable = "TRIVY_SERVER_URL=${module.trivy_security_scanner.jenkins_integration.trivy_server_url}"
      zap_environment_variable   = "ZAP_API_URL=${module.owasp_zap_testing.jenkins_integration.zap_api_url}"
      # grafana_environment_variable = "GRAFANA_URL=${module.grafana_monitoring.grafana_dashboard_url}"
      pipeline_usage            = "Use o endpoint /scan para integrar com pipelines Jenkins"
      health_check              = module.trivy_security_scanner.jenkins_integration.health_check_url
    }
  }
}