# Variáveis do Módulo Grafana Monitoring

variable "resource_group_name" {
  description = "Nome do grupo de recursos"
  type        = string
}

variable "location" {
  description = "Localização do Azure"
  type        = string
}

variable "prefix" {
  description = "Prefixo para recursos"
  type        = string
}

# Configurações do ACR
variable "acr_login_server" {
  description = "Servidor de login do ACR"
  type        = string
}

variable "acr_admin_username" {
  description = "Username admin do ACR"
  type        = string
  sensitive   = true
}

variable "acr_admin_password" {
  description = "Password admin do ACR"
  type        = string
  sensitive   = true
}

variable "acr_dependency" {
  description = "Dependência do ACR para garantir ordem"
  type        = any
  default     = null
}

# Configurações específicas do Grafana
variable "grafana_admin_password" {
  description = "Senha do admin do Grafana"
  type        = string
  default     = "admin123"
  sensitive   = true
}

variable "azure_subscription_id" {
  description = "ID da subscription Azure para integração"
  type        = string
  default     = ""
}

# IPs dos serviços para integração
variable "trivy_dashboard_ip" {
  description = "IP do dashboard Trivy para scraping"
  type        = string
  default     = ""
}

variable "zap_dashboard_ip" {
  description = "IP do dashboard OWASP ZAP para scraping"
  type        = string
  default     = ""
}

variable "jenkins_vm_ip" {
  description = "IP da VM Jenkins para scraping"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags para recursos"
  type        = map(string)
  default = {
    Environment = "Development"
    Service     = "Monitoring"
    Tool        = "Grafana"
  }
}