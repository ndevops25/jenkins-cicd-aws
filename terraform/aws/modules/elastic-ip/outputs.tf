output "jenkins_public_ip" {
  description = "Endereço IP público"
  value       = aws_eip.jenkins_eip.public_ip
}

output "sonarqube_public_ip" {
  description = "IP público (Elastic IP) do SonarQube"
  value       = aws_eip.sonarqube_eip.public_ip
}

output "jenkins_allocation_id" {
  description = "ID da alocação do Jenkins EIP"
  value       = aws_eip.jenkins_eip.allocation_id
}

output "sonarqube_allocation_id" {
  description = "ID da alocação do SonarQube EIP"
  value       = aws_eip.sonarqube_eip.allocation_id
}
