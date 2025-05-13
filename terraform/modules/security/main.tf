resource "aws_security_group" "jenkins" {
  name        = "${var.project_name}-${var.environment}-jenkins-sg"
  description = "Security group for Jenkins server"
  vpc_id      = var.vpc_id

  # SSH
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_ips
  }

  # Jenkins
  ingress {
    description = "Jenkins"
    from_port   = var.jenkins_port
    to_port     = var.jenkins_port
    protocol    = "tcp"
    cidr_blocks = var.allowed_ips
  }

  # Docker
  ingress {
    description = "Docker"
    from_port   = 2375
    to_port     = 2375
    protocol    = "tcp"
    cidr_blocks = var.allowed_ips
  }

  # Application Port
  ingress {
    description = "Application"
    from_port   = var.app_port
    to_port     = var.app_port
    protocol    = "tcp"
    cidr_blocks = var.allowed_ips
  }

  # Egress
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-jenkins-sg"
    }
  )
}