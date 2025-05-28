# VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support   = var.enable_dns_support

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-vpc"
    }
  )
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-igw"
    }
  )
}

data "aws_availability_zones" "available" {
  state = "available"
}

# Public Subnet 1
resource "aws_subnet" "public_1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_1_cidr
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-public-subnet-1"
    }
  )
}

# Public Subnet 2
resource "aws_subnet" "public_2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_2_cidr
  availability_zone       = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = true

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-public-subnet-2"
    }
  )
}

# Private Subnet 1 (para ECS)
# resource "aws_subnet" "private_1" {
#   vpc_id                  = aws_vpc.main.id
#   cidr_block              = var.private_subnet_1_cidr
#   availability_zone       = data.aws_availability_zones.available.names[0]
#   map_public_ip_on_launch = false

#   tags = merge(
#     var.tags,
#     {
#       Name = "${var.project_name}-${var.environment}-private-subnet-1"
#     }
#   )
# }

# # Private Subnet 2 (para ECS)
# resource "aws_subnet" "private_2" {
#   vpc_id                  = aws_vpc.main.id
#   cidr_block              = var.private_subnet_2_cidr
#   availability_zone       = data.aws_availability_zones.available.names[1]
#   map_public_ip_on_launch = false

#   tags = merge(
#     var.tags,
#     {
#       Name = "${var.project_name}-${var.environment}-private-subnet-2"
#     }
#   )
# }

# Route table associations para subnets públicas
resource "aws_route_table_association" "public_1" {
  subnet_id      = aws_subnet.public_1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_2" {
  subnet_id      = aws_subnet.public_2.id
  route_table_id = aws_route_table.public.id
}

# NAT Gateway em cada AZ para alta disponibilidade (opcional)
resource "aws_eip" "nat_1" {
  domain = "vpc"
  tags = merge(var.tags, { Name = "${var.project_name}-${var.environment}-nat-eip-1" })
}

# resource "aws_nat_gateway" "nat_1" {
#   allocation_id = aws_eip.nat_1.id
#   subnet_id     = aws_subnet.public_1.id

#   tags = merge(
#     var.tags,
#     {
#       Name = "${var.project_name}-${var.environment}-nat-1"
#     }
#   )
# }

# Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-public-rt"
    }
  )
}

# Route table para subnets privadas
# resource "aws_route_table" "private" {
#   vpc_id = aws_vpc.main.id

#   route {
#     cidr_block     = "0.0.0.0/0"
#     nat_gateway_id = aws_nat_gateway.nat_1.id
#   }

#   tags = merge(
#     var.tags,
#     {
#       Name = "${var.project_name}-${var.environment}-private-rt"
#     }
#   )
# }

# resource "aws_route_table_association" "private_1" {
#   subnet_id      = aws_subnet.private_1.id
#   route_table_id = aws_route_table.private.id
# }

# resource "aws_route_table_association" "private_2" {
#   subnet_id      = aws_subnet.private_2.id
#   route_table_id = aws_route_table.private.id
# }