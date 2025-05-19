# Criar par de chaves automaticamente
resource "tls_private_key" "sonarqube_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "sonarqube_key" {
  key_name   = var.sonarqube_key_name
  public_key = tls_private_key.sonarqube_key.public_key_openssh

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-sonarqube-key"
    }
  )
}

# Salvar chave privada localmente
resource "local_file" "sonarqube_private_key" {
  content  = tls_private_key.sonarqube_key.private_key_pem
  filename = pathexpand("~/.ssh/${var.sonarqube_key_name}.pem")
  file_permission = "0400"
}

resource "aws_instance" "sonarqube" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type  # Recomendado: t3.medium ou superior
  key_name               = var.sonarqube_key_name
  vpc_security_group_ids = var.sonarqube_security_group_ids
  subnet_id              = var.subnet_id
  user_data              = file("${path.module}/sonarqube.sh")
  
  iam_instance_profile   = aws_iam_instance_profile.sonarqube.name

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-sonarqube"
    }
  )
}



resource "aws_iam_role" "sonarqube" {
  name = "${var.project_name}-${var.environment}-sonarqube"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Effect = "Allow"
    }]
  })
}

resource "aws_iam_instance_profile" "sonarqube" {
  name = "${var.project_name}-${var.environment}-sonarqube-profile"
  role = aws_iam_role.sonarqube.name
}