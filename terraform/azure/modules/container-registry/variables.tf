variable "resource_group_name" {
  description = "O nome do grupo de recursos"
  type        = string
}

variable "location" {
  description = "A localização do Azure onde os recursos serão criados"
  type        = string
}

variable "prefix" {
  description = "O prefixo usado para todos os recursos neste módulo"
  type        = string
}

variable "sku" {
  description = "O SKU do Azure Container Registry"
  type        = string
  default     = "Standard"
}

variable "admin_enabled" {
  description = "Habilitar o usuário administrador para o registro de contêiner"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags para os recursos"
  type        = map(string)
  default     = {}
}