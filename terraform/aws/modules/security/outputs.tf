output "jenkins_security_group_id" {
  description = "ID do Security Group"
  value       = aws_security_group.jenkins.id
}

output "sonarqube_security_group_id" {
  description = "ID do Security Group"
  value       = aws_security_group.sonarqube.id
}