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

variable "subnet_id" {
  description = "O ID da subnet onde o Application Gateway será implantado"
  type        = string
}

variable "backend_address_pool_ip" {
  description = "O endereço IP para o pool de backend"
  type        = string
}

variable "backend_http_port" {
  description = "A porta HTTP para as configurações de backend"
  type        = number
  default     = 80
}

variable "sku_tier" {
  description = "O tier do SKU para o Application Gateway"
  type        = string
  default     = "Standard_v2"
}

variable "sku_size" {
  description = "O tamanho do SKU para o Application Gateway"
  type        = string
  default     = "Standard_v2"
}

variable "capacity" {
  description = "O número de instâncias do Application Gateway"
  type        = number
  default     = 2
}

variable "tags" {
  description = "Tags para os recursos"
  type        = map(string)
  default     = {}
}