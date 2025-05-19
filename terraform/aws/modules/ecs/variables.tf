variable "project_name" {
  description = "Nome do projeto"
  type        = string
}

variable "environment" {
  description = "Ambiente (dev, prod)"
  type        = string
}

variable "tags" {
  description = "Tags para recursos"
  type        = map(string)
}

variable "task_cpu" {
  description = "CPU para task do Fargate (em unidades vCPU)"
  type        = string
}

variable "task_memory" {
  description = "Memória para task do Fargate (em MB)"
  type        = string
}

variable "ecr_repository_url" {
  description = "URL do repositório ECR"
  type        = string
}

variable "app_port" {
  description = "Porta da aplicação"
  type        = number
}

variable "aws_region" {
  description = "Região AWS"
  type        = string
}

variable "desired_count" {
  description = "Número desejado de tasks"
  type        = number
}

variable "vpc_id" {
  description = "ID da VPC"
  type        = string
}

variable "private_subnet_ids" {
  description = "IDs das subnets privadas para ECS tasks"
  type        = list(string)
}

variable "public_subnet_ids" {
  description = "IDs das subnets públicas para ALB"
  type        = list(string)
}