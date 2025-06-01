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

variable "account_tier" {
  description = "O tier da conta de armazenamento"
  type        = string
  default     = "Standard"
}

variable "account_replication_type" {
  description = "O tipo de replicação da conta de armazenamento"
  type        = string
  default     = "LRS"
}

variable "container_name" {
  description = "O nome do container de armazenamento"
  type        = string
  default     = "tfstate"
}

variable "tags" {
  description = "Tags para os recursos"
  type        = map(string)
  default     = {}
}