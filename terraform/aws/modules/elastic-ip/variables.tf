variable "project_name" {
  description = "Nome do projeto"
  type        = string
}

variable "environment" {
  description = "Ambiente"
  type        = string
}

variable "jenkins_instance_id" {
  description = "ID da instância Jenkins EC2"
  type        = string
}

variable "sonarqube_instance_id" {
  description = "ID da instância SonarQube EC2"
  type        = string
}

variable "tags" {
  description = "Tags para recursos"
  type        = map(string)
  default     = {}
}