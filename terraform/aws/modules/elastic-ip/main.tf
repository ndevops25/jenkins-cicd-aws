resource "aws_eip" "jenkins_eip" {
  instance = var.jenkins_instance_id

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-eip"
    }
  )

  lifecycle {
    prevent_destroy = false
  }
}

resource "aws_eip_association" "jenkins_eip_assoc" {
  instance_id   = var.jenkins_instance_id
  allocation_id = aws_eip.jenkins_eip.id
}

# Elastic IP para o SonarQube
resource "aws_eip" "sonarqube_eip" {
  instance = var.sonarqube_instance_id
  
  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-sonarqube-eip"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_eip_association" "sonarqube_eip_assoc" {
  instance_id   = var.sonarqube_instance_id
  allocation_id = aws_eip.sonarqube_eip.id
}