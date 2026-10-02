# --- Naming and tagging ------------------------------------------------------
variable "project" {
  description = "Short project name used as the first part of every resource name."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9]{1,11}$", var.project))
    error_message = "project must be 2-12 lowercase alphanumeric characters (keeps ALB/target group names under 32 chars)."
  }
}

variable "environment" {
  description = "Deployment environment."
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be dev, staging or prod."
  }
}

variable "owner" {
  description = "Team or person responsible for the resources (Owner tag)."
  type        = string
}

variable "cost_center" {
  description = "Cost allocation tag."
  type        = string
  default     = "assessment"
}

variable "aws_region" {
  description = "AWS region."
  type        = string
  default     = "us-east-1"
}

# --- Network -----------------------------------------------------------------
variable "vpc_cidr" {
  description = "VPC CIDR block."
  type        = string
  default     = "10.20.0.0/16"
}

variable "enable_nat_gateway" {
  description = "Run tasks in private subnets behind a NAT gateway (adds ~USD 33/month)."
  type        = bool
  default     = false
}

variable "enable_flow_logs" {
  description = "Send rejected VPC traffic to CloudWatch Logs."
  type        = bool
  default     = true
}

variable "allowed_ingress_cidrs" {
  description = "CIDRs allowed to reach the load balancer."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "certificate_arn" {
  description = "Optional ACM certificate ARN; when set the ALB serves HTTPS and redirects HTTP."
  type        = string
  default     = ""
}

# --- Application -------------------------------------------------------------
variable "backend_port" {
  description = "Backend container port."
  type        = number
  default     = 3000
}

variable "frontend_port" {
  description = "Frontend container port."
  type        = number
  default     = 8080
}

variable "backend_desired_count" {
  description = "Minimum / initial number of backend tasks."
  type        = number
  default     = 1
}

variable "backend_max_count" {
  description = "Maximum number of backend tasks for auto scaling."
  type        = number
  default     = 3
}

variable "initial_image_tag" {
  description = "Image tag referenced by the first task definition. The pipeline replaces it with git-SHA tags."
  type        = string
  default     = "bootstrap"
}

variable "enable_container_insights" {
  description = "Enable ECS Container Insights."
  type        = bool
  default     = true
}

# --- Database ----------------------------------------------------------------
variable "db_instance_class" {
  description = "RDS instance class."
  type        = string
  default     = "db.t3.micro"
}

variable "db_multi_az" {
  description = "Enable Multi-AZ for RDS."
  type        = bool
  default     = false
}

# --- Observability -----------------------------------------------------------
variable "log_retention_days" {
  description = "CloudWatch Logs retention."
  type        = number
  default     = 14
}

variable "alert_email" {
  description = "E-mail address that receives CloudWatch alarm notifications (optional)."
  type        = string
  default     = ""
}

# --- CI/CD -------------------------------------------------------------------
variable "github_repository" {
  description = "GitHub repository (owner/name) allowed to deploy via OIDC."
  type        = string
}

variable "enable_github_oidc" {
  description = "Create the GitHub OIDC deploy role. Disable if the account does not allow IAM OIDC providers."
  type        = bool
  default     = true
}

variable "create_github_oidc_provider" {
  description = "Create the account-wide GitHub OIDC provider (set false if it already exists)."
  type        = bool
  default     = true
}
