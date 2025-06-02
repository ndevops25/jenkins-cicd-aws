# Criar par de chaves automaticamente
resource "tls_private_key" "jenkins_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "jenkins_key" {
  key_name   = var.jenkins_key_name
  public_key = tls_private_key.jenkins_key.public_key_openssh

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-jenkins-key"
    }
  )
}

# Salvar chave privada localmente
resource "local_file" "jenkins_private_key" {
  content  = tls_private_key.jenkins_key.private_key_pem
  filename = pathexpand("~/.ssh/${var.jenkins_key_name}.pem")
  file_permission = "0400"
}

# EC2 Instance
resource "aws_instance" "jenkins" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  key_name               = var.jenkins_key_name
  vpc_security_group_ids = var.jenkins_security_group_ids
  subnet_id              = var.subnet_id
  user_data              = file("${path.module}/jenkins.sh")

  iam_instance_profile = aws_iam_instance_profile.jenkins.name

  root_block_device {
    volume_size = var.volume_size
    volume_type = var.volume_type
    encrypted   = true
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-jenkins"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}