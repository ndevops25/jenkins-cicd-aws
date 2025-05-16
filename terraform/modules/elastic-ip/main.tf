resource "aws_eip" "main" {
  instance = var.instance_id

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
  instance_id   = var.instance_id
  allocation_id = aws_eip.main.id
}