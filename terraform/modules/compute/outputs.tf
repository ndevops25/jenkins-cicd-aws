output "instance_id" {
  description = "ID da instância EC2"
  value       = aws_instance.jenkins.id
}

output "instance_public_ip" {
  description = "IP público da instância"
  value       = aws_instance.jenkins.public_ip
}

output "instance_private_ip" {
  description = "IP privado da instância"
  value       = aws_instance.jenkins.private_ip
}