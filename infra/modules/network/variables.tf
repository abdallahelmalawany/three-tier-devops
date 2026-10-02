variable "name_prefix" {
  description = "Prefix for all resource names, e.g. threetier-dev."
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block of the VPC (a /16 is expected)."
  type        = string

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0)) && endswith(var.vpc_cidr, "/16")
    error_message = "vpc_cidr must be a valid /16 CIDR block."
  }
}

variable "az_count" {
  description = "Number of availability zones to spread subnets across (ALB and RDS subnet groups need at least 2)."
  type        = number
  default     = 2

  validation {
    condition     = var.az_count >= 2 && var.az_count <= 3
    error_message = "az_count must be 2 or 3."
  }
}

variable "enable_nat_gateway" {
  description = "Create a NAT gateway so workloads can run in the private app subnets. Disabled by default to save cost in sandbox accounts."
  type        = bool
  default     = false
}

variable "enable_flow_logs" {
  description = "Ship rejected VPC traffic to CloudWatch Logs."
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "Retention for the flow log group."
  type        = number
  default     = 7
}
