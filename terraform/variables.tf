variable "project_name" {
  description = "Nome do projeto"
  type        = string
  default     = "jenkins-cicd"
}

variable "environment" {
  description = "Ambiente"
  type        = string
  default     = "dev"
}

variable "aws_region" {
  description = "Região AWS"
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "CIDR da VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR da subnet pública"
  type        = string
  default     = "10.0.1.0/24"
}

variable "instance_type" {
  description = "Tipo da instância EC2"
  type        = string
  default     = "t2.medium"
}

variable "key_name" {
  description = "Nome da chave SSH"
  type        = string
}

variable "allowed_ips" {
  description = "IPs permitidos para acesso"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "jenkins_port" {
  description = "Porta do Jenkins"
  type        = number
  default     = 8080
}

variable "app_port" {
  description = "Porta da aplicação"
  type        = number
  default     = 5001
}

variable "volume_size" {
  description = "Tamanho do volume em GB"
  type        = number
  default     = 20
}