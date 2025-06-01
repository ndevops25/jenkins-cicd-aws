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

variable "subnet_id" {
  description = "O ID da subnet onde a VM será criada"
  type        = string
}

variable "vm_size" {
  description = "O tamanho da VM"
  type        = string
  default     = "Standard_D2s_v3"
}

variable "admin_username" {
  description = "O nome de usuário administrador para a VM"
  type        = string
  default     = "azureuser"
}

variable "admin_password" {
  description = "A senha do administrador para a VM (se autenticação por senha estiver habilitada)"
  type        = string
  default     = null
  sensitive   = true
}

variable "admin_ssh_key_data" {
  description = "A chave pública SSH para autenticação (opcional, usa a chave local por padrão)"
  type        = string
  default     = null
}

variable "disable_password_auth" {
  description = "Desabilitar autenticação por senha"
  type        = bool
  default     = true
}

variable "os_disk_size_gb" {
  description = "Tamanho do disco OS em GB"
  type        = number
  default     = 128
}

variable "custom_data" {
  description = "Dados de inicialização personalizados para a VM"
  type        = string
  default     = null
}

variable "public_ip_name" {
  description = "Nome do IP público"
  type        = string
}

variable "private_ip_address" {
  description = "Endereço IP privado estático para a VM"
  type        = string
}

variable "tags" {
  description = "Tags para os recursos"
  type        = map(string)
  default     = {}
}