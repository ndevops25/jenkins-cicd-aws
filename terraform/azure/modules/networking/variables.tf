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

variable "address_space" {
  description = "O espaço de endereço IP da rede virtual"
  type        = string
  default     = "10.0.0.0/16"
}

variable "app_subnet_prefix" {
  description = "O prefixo CIDR para a sub-rede de aplicativos"
  type        = string
  default     = "10.0.1.0/24"
}

variable "container_subnet_prefix" {
  description = "O prefixo CIDR para a sub-rede de contêineres"
  type        = string
  default     = "10.0.2.0/24"
}

variable "gateway_subnet_prefix" {
  description = "O prefixo CIDR para a sub-rede do gateway"
  type        = string
  default     = "10.0.0.0/24"
}

variable "tags" {
  description = "Tags para os recursos"
  type        = map(string)
  default     = {}
}