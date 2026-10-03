module "network" {
  source = "../../modules/network"

  name_prefix        = local.name_prefix
  vpc_cidr           = var.vpc_cidr
  az_count           = 2
  enable_nat_gateway = var.enable_nat_gateway
  enable_flow_logs   = var.enable_flow_logs
  log_retention_days = var.log_retention_days
}

module "security" {
  source = "../../modules/security"

  name_prefix           = local.name_prefix
  vpc_id                = module.network.vpc_id
  allowed_ingress_cidrs = var.allowed_ingress_cidrs
  enable_https          = var.certificate_arn != ""
  backend_port          = var.backend_port
  frontend_port         = var.frontend_port
}

module "ecr" {
  source = "../../modules/ecr"

  name_prefix  = local.name_prefix
  repositories = local.services
  force_delete = var.environment != "prod"
}

module "database" {
  source = "../../modules/database"

  name_prefix            = local.name_prefix
  subnet_ids             = module.network.data_subnet_ids
  security_group_id      = module.security.database_security_group_id
  instance_class         = var.db_instance_class
  multi_az               = var.db_multi_az
  create_parameter_group = var.db_create_parameter_group
  deletion_protection    = var.environment == "prod"
  skip_final_snapshot    = var.environment != "prod"
}

module "ecs" {
  source = "../../modules/ecs"
  providers = {
    aws            = aws
    aws.iam_policy = aws.iam_policy
  }

  name_prefix         = local.name_prefix
  aws_region          = var.aws_region
  vpc_id              = module.network.vpc_id
  public_subnet_ids   = module.network.public_subnet_ids
  private_subnet_ids  = module.network.app_subnet_ids
  use_private_subnets = module.network.nat_gateway_enabled

  alb_security_group_id      = module.security.alb_security_group_id
  backend_security_group_id  = module.security.backend_security_group_id
  frontend_security_group_id = module.security.frontend_security_group_id
  certificate_arn            = var.certificate_arn

  repository_urls = module.ecr.repository_urls
  repository_arns = module.ecr.repository_arns
  image_tag       = var.initial_image_tag

  backend = {
    port          = var.backend_port
    cpu           = 256
    memory        = 512
    desired_count = var.backend_desired_count
    max_count     = var.backend_max_count
  }

  frontend = {
    port          = var.frontend_port
    cpu           = 256
    memory        = 512
    desired_count = 1
  }

  database = {
    host                   = module.database.address
    port                   = module.database.port
    name                   = module.database.database_name
    username               = module.database.master_username
    password_parameter_arn = module.database.password_parameter_arn
  }

  enable_container_insights = var.enable_container_insights
  enable_autoscaling        = var.enable_autoscaling
  log_retention_days        = var.log_retention_days
}

module "monitoring" {
  source = "../../modules/monitoring"

  name_prefix               = local.name_prefix
  aws_region                = var.aws_region
  alert_email               = var.alert_email
  alb_arn_suffix            = module.ecs.alb_arn_suffix
  target_group_arn_suffixes = module.ecs.target_group_arn_suffixes
  ecs_cluster_name          = module.ecs.cluster_name
  ecs_service_names         = module.ecs.service_names
  backend_log_group_name    = module.ecs.log_group_names["backend"]
  db_instance_identifier    = module.database.instance_identifier
  enable_log_metric_alarm   = var.enable_log_metric_alarm
}

module "github_oidc" {
  source = "../../modules/github-oidc"
  count  = var.enable_github_oidc ? 1 : 0

  name_prefix          = local.name_prefix
  github_repository    = var.github_repository
  environment          = var.environment
  create_oidc_provider = var.create_github_oidc_provider
  ecr_repository_arns  = values(module.ecr.repository_arns)
  ecs_service_arns     = values(module.ecs.service_arns)
  passable_role_arns   = [module.ecs.execution_role_arn, module.ecs.task_role_arn]
}
