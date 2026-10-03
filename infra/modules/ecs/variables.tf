variable "name_prefix" {
  description = "Prefix for all resource names."
  type        = string
}

variable "aws_region" {
  description = "Region used by the awslogs log driver."
  type        = string
}

variable "vpc_id" {
  description = "VPC for the target groups."
  type        = string
}

variable "public_subnet_ids" {
  description = "Public subnets for the ALB (and tasks when use_private_subnets = false)."
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "Private app subnets for tasks when use_private_subnets = true."
  type        = list(string)
}

variable "use_private_subnets" {
  description = "Place tasks in private subnets (requires a NAT gateway or VPC endpoints)."
  type        = bool
}

variable "alb_security_group_id" {
  description = "Security group of the ALB."
  type        = string
}

variable "backend_security_group_id" {
  description = "Security group of the backend tasks."
  type        = string
}

variable "frontend_security_group_id" {
  description = "Security group of the frontend tasks."
  type        = string
}

variable "certificate_arn" {
  description = "ACM certificate ARN for HTTPS. Empty = HTTP only."
  type        = string
  default     = ""
}

variable "repository_urls" {
  description = "ECR repository URLs keyed by service name (backend, frontend)."
  type        = map(string)
}

variable "repository_arns" {
  description = "ECR repository ARNs keyed by service name."
  type        = map(string)
}

variable "image_tag" {
  description = "Image tag used when Terraform registers a task definition. Afterwards the pipeline deploys git-SHA tags."
  type        = string
}

variable "backend" {
  description = "Backend service sizing."
  type = object({
    port          = number
    cpu           = number
    memory        = number
    desired_count = number
    max_count     = number
  })
}

variable "frontend" {
  description = "Frontend service sizing."
  type = object({
    port          = number
    cpu           = number
    memory        = number
    desired_count = number
  })
}

variable "database" {
  description = "Connection settings injected into the backend container."
  type = object({
    host                   = string
    port                   = number
    name                   = string
    username               = string
    password_parameter_arn = string
  })
}

variable "enable_container_insights" {
  description = "Enable CloudWatch Container Insights on the cluster."
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "Retention for container log groups."
  type        = number
  default     = 14
}

variable "enable_autoscaling" {
  description = "CPU target-tracking auto scaling for the backend service."
  type        = bool
  default     = true
}
