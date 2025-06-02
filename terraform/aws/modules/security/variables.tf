variable "project_name" {
  description = "Nome do projeto"
  type        = string
}

variable "environment" {
  description = "Ambiente"
  type        = string
}

variable "vpc_id" {
  description = "ID da VPC"
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

variable "tags" {
  description = "Tags para recursos"
  type        = map(string)
  default     = {}
}