# terraform/modules/ecs/outputs.tf

output "cluster_id" {
  description = "ID do cluster ECS"
  value       = aws_ecs_cluster.main.id
}

output "cluster_arn" {
  description = "ARN do cluster ECS"
  value       = aws_ecs_cluster.main.arn
}

output "cluster_name" {
  description = "Nome do cluster ECS"
  value       = aws_ecs_cluster.main.name
}

output "service_id" {
  description = "ID do service ECS"
  value       = aws_ecs_service.app.id
}

output "service_name" {
  description = "Nome do service ECS"
  value       = aws_ecs_service.app.name
}

output "task_definition_arn" {
  description = "ARN da task definition"
  value       = aws_ecs_task_definition.app.arn
}

output "task_definition_family" {
  description = "Família da task definition"
  value       = aws_ecs_task_definition.app.family
}

output "alb_arn" {
  description = "ARN do Application Load Balancer"
  value       = aws_lb.app.arn
}

output "alb_dns_name" {
  description = "DNS name do ALB"
  value       = aws_lb.app.dns_name
}

output "alb_zone_id" {
  description = "Zone ID do ALB"
  value       = aws_lb.app.zone_id
}

output "app_url" {
  description = "URL da aplicação"
  value       = "http://${aws_lb.app.dns_name}"
}

output "target_group_arn" {
  description = "ARN do target group"
  value       = aws_lb_target_group.app.arn
}

output "alb_security_group_id" {
  description = "ID do security group do ALB"
  value       = aws_security_group.alb.id
}

output "ecs_tasks_security_group_id" {
  description = "ID do security group das tasks ECS"
  value       = aws_security_group.ecs_tasks.id
}

output "ecs_execution_role_arn" {
  description = "ARN da role de execução do ECS"
  value       = aws_iam_role.ecs_execution_role.arn
}

output "cloudwatch_log_group_name" {
  description = "Nome do log group do CloudWatch"
  value       = aws_cloudwatch_log_group.ecs.name
}

output "cloudwatch_log_group_arn" {
  description = "ARN do log group do CloudWatch"
  value       = aws_cloudwatch_log_group.ecs.arn
}