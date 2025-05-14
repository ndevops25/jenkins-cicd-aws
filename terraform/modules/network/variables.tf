variable "project_name" {
  description = "Nome do projeto"
  type        = string
}

variable "environment" {
  description = "Ambiente (dev, prod)"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block para VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_1_cidr" {
  description = "CIDR block para subnet pública 1"
  type        = string
}

variable "public_subnet_2_cidr" {
  description = "CIDR block para subnet pública 2"
  type        = string
}

variable "private_subnet_1_cidr" {
  description = "CIDR block para subnet privada 1"
  type        = string
}

variable "private_subnet_2_cidr" {
  description = "CIDR block para subnet privada 2"
  type        = string
}

variable "availability_zone" {
  description = "Zona de disponibilidade"
  type        = string
}

variable "enable_dns_hostnames" {
  description = "Habilitar DNS hostnames"
  type        = bool
  default     = true
}

variable "enable_dns_support" {
  description = "Habilitar DNS support"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags para recursos"
  type        = map(string)
  default     = {}
}

