variable "name" {
  description = "O nome do grupo de recursos"
  type        = string
}

variable "location" {
  description = "A localização do Azure onde o grupo de recursos será criado"
  type        = string
}

variable "tags" {
  description = "Tags para o grupo de recursos"
  type        = map(string)
  default     = {}
}