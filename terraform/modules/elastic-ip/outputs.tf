output "public_ip" {
  description = "Endereço IP público"
  value       = aws_eip.main.public_ip
}

output "allocation_id" {
  description = "ID da alocação do EIP"
  value       = aws_eip.main.allocation_id
}