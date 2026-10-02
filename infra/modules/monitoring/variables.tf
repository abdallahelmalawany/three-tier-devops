variable "name_prefix" {
  description = "Prefix for all resource names."
  type        = string
}

variable "aws_region" {
  description = "Region shown in dashboard widgets."
  type        = string
}

variable "alert_email" {
  description = "E-mail address subscribed to the alerts topic. Empty = no subscription."
  type        = string
  default     = ""
}

variable "alb_arn_suffix" {
  description = "ALB ARN suffix."
  type        = string
}

variable "target_group_arn_suffixes" {
  description = "Target group ARN suffixes keyed by service."
  type        = map(string)
}

variable "ecs_cluster_name" {
  description = "ECS cluster name."
  type        = string
}

variable "ecs_service_names" {
  description = "ECS service names keyed by service."
  type        = map(string)
}

variable "backend_log_group_name" {
  description = "Log group of the backend containers."
  type        = string
}

variable "db_instance_identifier" {
  description = "RDS instance identifier."
  type        = string
}

variable "http_5xx_threshold" {
  description = "Number of target 5xx responses per 5 minutes that triggers an alarm."
  type        = number
  default     = 5
}

variable "error_log_threshold" {
  description = "Number of backend error log lines per 5 minutes that triggers an alarm."
  type        = number
  default     = 1
}

variable "latency_p95_threshold_seconds" {
  description = "p95 latency (seconds) that triggers an alarm."
  type        = number
  default     = 1
}

variable "cpu_threshold_percent" {
  description = "CPU utilisation (%) that triggers ECS and RDS alarms."
  type        = number
  default     = 80
}

variable "memory_threshold_percent" {
  description = "Memory utilisation (%) that triggers ECS alarms."
  type        = number
  default     = 80
}

variable "db_free_storage_threshold_gib" {
  description = "Free storage (GiB) under which the RDS alarm fires."
  type        = number
  default     = 2
}
