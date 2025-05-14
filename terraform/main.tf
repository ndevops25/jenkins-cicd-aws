# VPC Module
module "network" {
  source = "./modules/network"

  project_name       = var.project_name
  environment        = var.environment
  vpc_cidr           = var.vpc_cidr
  public_subnet_1_cidr  = var.public_subnet_1_cidr
  public_subnet_2_cidr  = var.public_subnet_2_cidr
  private_subnet_1_cidr = var.private_subnet_1_cidr
  private_subnet_2_cidr = var.private_subnet_2_cidr
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

# Módulo ECR (deve vir antes do ECS)
module "ecr" {
  source = "./modules/ecr"

  project_name = var.project_name
  environment  = var.environment
  tags         = local.common_tags
}

# Módulo ECS
module "ecs" {
  source = "./modules/ecs"

  # Configurações básicas
  project_name = var.project_name
  environment  = var.environment
  tags         = local.common_tags
  aws_region   = var.aws_region

  # Configurações da task
  task_cpu    = var.task_cpu    # 0.25 vCPU
  task_memory = var.task_memory   # 0.5 GB
  app_port    = var.app_port
  
  # Número de instâncias
  desired_count = 1

  # Referências de outros módulos
  ecr_repository_url = module.ecr.repository_url
  vpc_id            = module.network.vpc_id
  private_subnet_ids = module.network.private_subnet_ids  # Se você tiver subnet privada
  public_subnet_ids  = module.network.public_subnet_ids
}