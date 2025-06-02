output "jenkins_instance_id" {
  description = "ID da instância EC2"
  value       = aws_instance.jenkins.id
}

output "jenkins_instance_public_ip" {
  description = "IP público da instância"
  value       = aws_instance.jenkins.public_ip
}

output "jenkins_instance_private_ip" {
  description = "IP privado da instância"
  value       = aws_instance.jenkins.private_ip
}

// SONARQUBE

output "sonarqube_instance_id" {
  description = "ID da instância EC2 do SonarQube"
  value       = aws_instance.sonarqube.id
}

output "sonarqube_instance_private_ip" {
  description = "IP privado da instância do SonarQube"
  value       = aws_instance.sonarqube.private_ip
}

output "sonarqube_iam_role_name" {
  description = "Nome da IAM Role para o SonarQube"
  value       = aws_iam_role.sonarqube.name
}

output "sonarqube_iam_role_arn" {
  description = "ARN da IAM Role para o SonarQube"
  value       = aws_iam_role.sonarqube.arn
}

output "sonarqube_instance_profile_name" {
  description = "Nome do Instance Profile do SonarQube"
  value       = aws_iam_instance_profile.sonarqube.name
}