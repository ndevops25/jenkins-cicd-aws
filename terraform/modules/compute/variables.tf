variable "project_name" {
  description = "Nome do projeto"
  type        = string
}

variable "environment" {
  description = "Ambiente"
  type        = string
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

variable "subnet_id" {
  description = "ID da subnet"
  type        = string
}

variable "security_group_ids" {
  description = "IDs dos Security Groups"
  type        = list(string)
}

variable "volume_size" {
  description = "Tamanho do volume root em GB"
  type        = number
  default     = 20
}

variable "volume_type" {
  description = "Tipo do volume EBS"
  type        = string
  default     = "gp3"
}

variable "tags" {
  description = "Tags para recursos"
  type        = map(string)
  default     = {}
}