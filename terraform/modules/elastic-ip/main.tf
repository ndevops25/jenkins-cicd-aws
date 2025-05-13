resource "aws_eip" "main" {
  instance = var.instance_id

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-eip"
    }
  )
}