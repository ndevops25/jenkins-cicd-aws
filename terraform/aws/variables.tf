variable "project_name" {
  description = "Nome do projeto"
  type        = string
  default     = "devsec ops-cicd"
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

variable "public_subnet_1_cidr" {
  description = "CIDR block para subnet pública 1"
  type        = string
  default     = "10.0.10.0/24"  # Mudado de 10.0.1.0/24
}

variable "public_subnet_2_cidr" {
  description = "CIDR block para subnet pública 2"
  type        = string
  default     = "10.0.20.0/24"  # Mudado de 10.0.2.0/24
}

variable "private_subnet_1_cidr" {
  description = "CIDR block para subnet privada 1"
  type        = string
  default     = "10.0.30.0/24"  # Mudado de 10.0.3.0/24
}

variable "private_subnet_2_cidr" {
  description = "CIDR block para subnet privada 2"
  type        = string
  default     = "10.0.40.0/24"  # Mudado de 10.0.4.0/24
}

variable "instance_type" {
  description = "Tipo da instância EC2"
  type        = string
  default     = "t2.medium"
}

variable "jenkins_key_name" {
  description = "Nome da chave Jenkins SSH"
  type        = string
}

variable "sonarqube_key_name" {
  description = "Nome da chave SonarQube SSH"
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

variable "task_cpu" {
  description = "CPU para task do Fargate (em unidades vCPU)"
  type        = string
  default     = "256"  # 0.25 vCPU
}

variable "task_memory" {
  description = "Memória para task do Fargate (em MB)"
  type        = string
  default     = "512"  # 0.5 GB
}