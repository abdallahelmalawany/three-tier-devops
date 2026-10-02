output "cluster_name" {
  description = "ECS cluster name."
  value       = aws_ecs_cluster.this.name
}

output "service_names" {
  description = "ECS service names keyed by service."
  value       = { for k, s in aws_ecs_service.service : k => s.name }
}

output "service_arns" {
  description = "ECS service ARNs keyed by service."
  value       = { for k, s in aws_ecs_service.service : k => s.id }
}

output "task_definition_families" {
  description = "Task definition families keyed by service."
  value       = { for k, td in aws_ecs_task_definition.service : k => td.family }
}

output "execution_role_arn" {
  description = "Task execution role ARN."
  value       = aws_iam_role.execution.arn
}

output "task_role_arn" {
  description = "Task (application) role ARN."
  value       = aws_iam_role.task.arn
}

output "log_group_names" {
  description = "Container log groups keyed by service."
  value       = { for k, lg in aws_cloudwatch_log_group.service : k => lg.name }
}

output "alb_dns_name" {
  description = "Public DNS name of the load balancer."
  value       = aws_lb.this.dns_name
}

output "alb_arn_suffix" {
  description = "ALB ARN suffix (CloudWatch dimension LoadBalancer)."
  value       = aws_lb.this.arn_suffix
}

output "target_group_arn_suffixes" {
  description = "Target group ARN suffixes keyed by service (CloudWatch dimension TargetGroup)."
  value       = { for k, tg in aws_lb_target_group.service : k => tg.arn_suffix }
}
