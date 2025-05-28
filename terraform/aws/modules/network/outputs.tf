# terraform/modules/vpc/outputs.tf

output "vpc_id" {
  description = "ID da VPC"
  value       = aws_vpc.main.id
}

output "vpc_arn" {
  description = "ARN da VPC"
  value       = aws_vpc.main.arn
}

output "vpc_cidr_block" {
  description = "CIDR block da VPC"
  value       = aws_vpc.main.cidr_block
}

# Outputs de subnets públicas
output "public_subnet_ids" {
  description = "Lista de IDs das subnets públicas"
  value       = [aws_subnet.public_1.id, aws_subnet.public_2.id]
}

output "public_subnet_arns" {
  description = "Lista de ARNs das subnets públicas"
  value       = [aws_subnet.public_1.arn, aws_subnet.public_2.arn]
}

output "public_subnet_cidr_blocks" {
  description = "Lista de CIDR blocks das subnets públicas"
  value       = [aws_subnet.public_1.cidr_block, aws_subnet.public_2.cidr_block]
}

# Outputs de subnets privadas
output "private_subnet_ids" {
  description = "Lista de IDs das subnets privadas"
  value       = [aws_subnet.private_1.id, aws_subnet.private_2.id]
}

# output "private_subnet_arns" {
#   description = "Lista de ARNs das subnets privadas"
#   value       = [aws_subnet.private_1.arn, aws_subnet.private_2.arn]
# }

# output "private_subnet_cidr_blocks" {
#   description = "Lista de CIDR blocks das subnets privadas"
#   value       = [aws_subnet.private_1.cidr_block, aws_subnet.private_2.cidr_block]
# }

# Outputs individuais (para compatibilidade com código legado)
output "public_subnet_1_id" {
  description = "ID da primeira subnet pública"
  value       = aws_subnet.public_1.id
}

output "public_subnet_2_id" {
  description = "ID da segunda subnet pública"
  value       = aws_subnet.public_2.id
}

# output "private_subnet_1_id" {
#   description = "ID da primeira subnet privada"
#   value       = aws_subnet.private_1.id
# }

# output "private_subnet_2_id" {
#   description = "ID da segunda subnet privada"
#   value       = aws_subnet.private_2.id
# }

# Internet Gateway
output "internet_gateway_id" {
  description = "ID do Internet Gateway"
  value       = aws_internet_gateway.main.id
}

output "internet_gateway_arn" {
  description = "ARN do Internet Gateway"
  value       = aws_internet_gateway.main.arn
}

# NAT Gateway(s)
output "nat_gateway_ids" {
  description = "Lista de IDs dos NAT Gateways"
  value       = [aws_nat_gateway.nat_1.id]
}

output "nat_gateway_public_ips" {
  description = "Lista de IPs públicos dos NAT Gateways"
  value       = [aws_nat_gateway.nat_1.public_ip]
}

# Elastic IPs
output "nat_eip_ids" {
  description = "Lista de IDs dos Elastic IPs usados pelos NAT Gateways"
  value       = [aws_eip.nat_1.id]
}

# output "nat_eip_public_ips" {
#   description = "Lista de endereços IP públicos dos Elastic IPs"
#   value       = [aws_eip.nat_1.public_ip]
# }

# # Route Tables
# output "public_route_table_id" {
#   description = "ID da route table pública"
#   value       = aws_route_table.public.id
# }

# output "private_route_table_id" {
#   description = "ID da route table privada"
#   value       = aws_route_table.private.id
# }

# Availability Zones
output "availability_zones" {
  description = "Lista de Availability Zones usadas"
  value       = distinct([
    aws_subnet.public_1.availability_zone,
    aws_subnet.public_2.availability_zone
  ])
}

# Compatibilidade com código antigo (DEPRECATED - manter temporariamente)
output "public_subnet_id" {
  description = "ID da primeira subnet pública (DEPRECATED - use public_subnet_ids)"
  value       = aws_subnet.public_1.id
}

# Resumo da configuração
output "vpc_summary" {
  description = "Resumo da configuração da VPC"
  value = {
    vpc_id              = aws_vpc.main.id
    vpc_cidr            = aws_vpc.main.cidr_block
    public_subnet_count = length([aws_subnet.public_1.id, aws_subnet.public_2.id])
    private_subnet_count = length([aws_subnet.private_1.id, aws_subnet.private_2.id])
    availability_zones  = distinct([
      aws_subnet.public_1.availability_zone,
      aws_subnet.public_2.availability_zone
    ])
    nat_gateways       = length([aws_nat_gateway.nat_1.id])
  }
}