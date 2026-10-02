output "app_url" {
  description = "Public URL of the application."
  value       = "${var.certificate_arn == "" ? "http" : "https"}://${module.ecs.alb_dns_name}"
}

output "ecr_repository_urls" {
  description = "ECR repositories for the backend and frontend images."
  value       = module.ecr.repository_urls
}

output "ecs_cluster_name" {
  description = "ECS cluster name."
  value       = module.ecs.cluster_name
}

output "ecs_service_names" {
  description = "ECS service names."
  value       = module.ecs.service_names
}

output "database_endpoint" {
  description = "RDS endpoint (private; reachable from the backend tasks only)."
  value       = "${module.database.address}:${module.database.port}"
}

output "cloudwatch_dashboard" {
  description = "CloudWatch dashboard with the golden signals of all tiers."
  value       = "https://${var.aws_region}.console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards/dashboard/${module.monitoring.dashboard_name}"
}

output "alerts_topic_arn" {
  description = "SNS topic receiving all alarms."
  value       = module.monitoring.alerts_topic_arn
}

# Values to copy into the GitHub repository settings (Settings > Secrets and
# variables > Actions > Variables). None of them is secret.
output "github_actions_variables" {
  description = "Repository variables used by the CI/CD workflow."
  value = {
    AWS_REGION          = var.aws_region
    NAME_PREFIX         = local.name_prefix
    AWS_DEPLOY_ROLE_ARN = var.enable_github_oidc ? module.github_oidc[0].role_arn : "(OIDC disabled - use AWS access key secrets)"
    APP_URL             = "${var.certificate_arn == "" ? "http" : "https"}://${module.ecs.alb_dns_name}"
  }
}
