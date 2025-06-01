variable "prefix" {
  description = "Prefixo usado para todos os recursos"
  type        = string
  default     = "jenkins-cicd"
}

variable "environment" {
  description = "Tipo de ambiente dos recursos"
  type        = string
  default     = "prod"
}

variable "location" {
  description = "Região do Azure onde os recursos serão criados"
  type        = string
  default     = "eastus"
}

variable "address_space" {
  description = "O espaço de endereço IP da rede virtual"
  type        = string
  default     = "10.0.0.0/16"
}

variable "admin_username" {
  description = "Nome de usuário para as VMs"
  type        = string
  default     = "azureuser"
}

variable "admin_password" {
  description = "Senha para as VMs"
  type        = string
  sensitive   = true
}

variable "jenkins_vm_size" {
  description = "Tamanho da VM para Jenkins"
  type        = string
  default     = "Standard_D2s_v3"
}

variable "sonarqube_vm_size" {
  description = "Tamanho da VM para SonarQube"
  type        = string
  default     = "Standard_D2s_v3"
}

variable "jenkins_private_ip" {
  description = "Endereço IP privado para a VM Jenkins"
  type        = string
  default     = "10.0.1.10"
}

variable "sonarqube_private_ip" {
  description = "Endereço IP privado para a VM SonarQube"
  type        = string
  default     = "10.0.1.11"
}

variable "container_image" {
  description = "Imagem Docker para o container"
  type        = string
  default     = "sample-app"
}

variable "container_version" {
  description = "Versão da imagem Docker"
  type        = string
  default     = "latest"
}

variable "container_port" {
  description = "Porta exposta pelo container"
  type        = number
  default     = 5001
}

variable "container_cpu" {
  description = "CPU alocada para o container (em cores)"
  type        = number
  default     = 1
}

variable "container_memory" {
  description = "Memória alocada para o container (em GB)"
  type        = number
  default     = 2
}

variable "container_private_ip" {
  description = "Endereço IP privado para o Container Instance"
  type        = string
  default     = "10.0.2.10"
}

variable "tags" {
  description = "Tags para os recursos"
  type        = map(string)
  default = {
    Environment = "Development"
    Project     = "Jenkins-CICD"
  }
}


# Variáveis AKS
# Configurações da aplicação Python
variable "python_app_image" {
  description = "Imagem Docker da aplicação Python"
  type        = string
  default     = "python:3.11-slim"  # Será substituída pelo Jenkins
}

variable "python_app_port" {
  description = "Porta da aplicação Python"
  type        = number
  default     = 8000
}

# Recursos do ACI
variable "aci_cpu_cores" {
  description = "CPU cores para o container"
  type        = string
  default     = "0.5"
}

variable "aci_memory_gb" {
  description = "Memória para o container"
  type        = string
  default     = "1.0"
}

# Variáveis de ambiente da aplicação
variable "python_app_env_vars" {
  description = "Variáveis de ambiente da aplicação Python"
  type        = map(string)
  default = {
    "PYTHONUNBUFFERED" = "1"
    "PORT"             = "8000"
    "ENV"              = "production"
    "DEBUG"            = "false"
  }
}

variable "python_app_secrets" {
  description = "Variáveis secretas da aplicação"
  type        = map(string)
  default     = {}
  sensitive   = true
}

variable "python_startup_commands" {
  description = "Comandos para iniciar a aplicação Python"
  type        = list(string)
  default     = [
    "python",
    "-m",
    "uvicorn",
    "main:app",
    "--host",
    "0.0.0.0",
    "--port",
    "8000"
  ]
}