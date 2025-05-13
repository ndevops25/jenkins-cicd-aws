# VPC Module
module "network" {
  source = "./modules/network"

  project_name       = var.project_name
  environment        = var.environment
  vpc_cidr           = var.vpc_cidr
  public_subnet_cidr = var.public_subnet_cidr
  availability_zone  = "${var.aws_region}a"
  tags               = local.common_tags
}

# Security Module
module "security" {
  source = "./modules/security"

  project_name = var.project_name
  environment  = var.environment
  vpc_id       = module.network.vpc_id
  allowed_ips  = var.allowed_ips
  jenkins_port = var.jenkins_port
  app_port     = var.app_port
  tags         = local.common_tags
}

# Compute Module
module "compute" {
  source = "./modules/compute"

  project_name       = var.project_name
  environment        = var.environment
  instance_type      = var.instance_type
  key_name           = var.key_name
  subnet_id          = module.network.public_subnet_id
  security_group_ids = [module.security.security_group_id]
  volume_size        = var.volume_size
  tags               = local.common_tags
}

# Elastic IP Module
module "elastic_ip" {
  source = "./modules/elastic-ip"

  project_name = var.project_name
  environment  = var.environment
  instance_id  = module.compute.instance_id
  tags         = local.common_tags
}