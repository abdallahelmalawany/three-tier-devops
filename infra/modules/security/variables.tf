variable "name_prefix" {
  description = "Prefix for all resource names."
  type        = string
}

variable "vpc_id" {
  description = "VPC the security groups belong to."
  type        = string
}

variable "allowed_ingress_cidrs" {
  description = "CIDR ranges allowed to reach the public load balancer."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "enable_https" {
  description = "Open port 443 on the load balancer (requires an ACM certificate)."
  type        = bool
  default     = false
}

variable "backend_port" {
  description = "Container port of the backend API."
  type        = number
}

variable "frontend_port" {
  description = "Container port of the frontend."
  type        = number
}

variable "database_port" {
  description = "PostgreSQL port."
  type        = number
  default     = 5432
}
