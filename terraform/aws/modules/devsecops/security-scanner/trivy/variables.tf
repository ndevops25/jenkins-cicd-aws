# Variáveis do Módulo Trivy Security Scanner

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

variable "tags" {
  description = "Tags para recursos"
  type        = map(string)
  default = {
    Environment = "Development"
    Service     = "Security"
    Tool        = "Trivy"
  }
}