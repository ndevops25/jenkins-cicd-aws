output "jenkins_url" {
  description = "URL para acessar o Jenkins"
  value       = "http://${module.elastic_ip.public_ip}:${var.jenkins_port}"
}

output "app_url" {
  description = "URL para acessar a aplicação"
  value       = "http://${module.elastic_ip.public_ip}:${var.app_port}"
}

output "ssh_connection" {
  description = "Comando SSH para conectar ao servidor"
  value       = "ssh -i ~/.ssh/${var.key_name}.pem ubuntu@${module.elastic_ip.public_ip}"
}

output "jenkins_initial_password" {
  description = "Comando para obter a senha inicial do Jenkins"
  value       = "sudo cat /var/lib/jenkins/secrets/initialAdminPassword"
}

output "vpc_id" {
  description = "ID da VPC"
  value       = module.network.vpc_id
}

output "public_subnet_id" {
  description = "ID da subnet pública"
  value       = module.network.public_subnet_id
}

output "security_group_id" {
  description = "ID do Security Group"
  value       = module.security.security_group_id
}

output "instance_id" {
  description = "ID da instância EC2"
  value       = module.compute.instance_id
}