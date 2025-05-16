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

output "elastic_ip" {
  description = "Elastic IP do Jenkins"
  value       = module.elastic_ip.public_ip
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

# ECS E ALB
# Adicionar ao terraform/outputs.tf existente

# Outputs do ECS
output "ecs_cluster_name" {
  description = "Nome do cluster ECS"
  value       = module.ecs.cluster_name
}

output "ecs_service_name" {
  description = "Nome do service ECS"
  value       = module.ecs.service_name
}

output "alb_dns_name" {
  description = "DNS do Application Load Balancer"
  value       = module.ecs.alb_dns_name
}

output "application_url" {
  description = "URL completa da aplicação"
  value       = module.ecs.app_url
}

output "ecr_repository_url" {
  description = "URL do repositório ECR"
  value       = module.ecr.repository_url
}

output "ecs_task_definition_family" {
  description = "Família da task definition para updates"
  value       = module.ecs.task_definition_family
}