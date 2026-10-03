variable "name_prefix" {
  description = "Prefix for all resource names."
  type        = string
}

variable "subnet_ids" {
  description = "Private subnets for the DB subnet group (at least two AZs)."
  type        = list(string)
}

variable "security_group_id" {
  description = "Security group attached to the instance."
  type        = string
}

variable "engine_major_version" {
  description = "PostgreSQL major version; RDS picks the latest minor and auto-upgrades it."
  type        = string
  default     = "16"
}

variable "instance_class" {
  description = "RDS instance class."
  type        = string
  default     = "db.t3.micro"
}

variable "database_name" {
  description = "Name of the application database."
  type        = string
  default     = "app"
}

variable "master_username" {
  description = "Master user name."
  type        = string
  default     = "app_admin"
}

variable "password_version" {
  description = "Bump to rotate the master password (write-only arguments only change when this does)."
  type        = number
  default     = 1
}

variable "port" {
  description = "Database port."
  type        = number
  default     = 5432
}

variable "allocated_storage" {
  description = "Initial storage in GiB."
  type        = number
  default     = 20
}

variable "max_allocated_storage" {
  description = "Upper bound for storage autoscaling in GiB (0 disables autoscaling)."
  type        = number
  default     = 0
}

variable "multi_az" {
  description = "Run a synchronous standby in a second AZ."
  type        = bool
  default     = false
}

variable "backup_retention_days" {
  description = "Automated backup retention in days."
  type        = number
  default     = 1
}

variable "apply_immediately" {
  description = "Apply modifications immediately instead of in the maintenance window."
  type        = bool
  default     = true
}

variable "deletion_protection" {
  description = "Prevent the instance from being deleted."
  type        = bool
  default     = false
}

variable "skip_final_snapshot" {
  description = "Skip the final snapshot on destroy."
  type        = bool
  default     = true
}

variable "create_parameter_group" {
  description = "Create the hardened parameter group (forced TLS, slow-query and connection logging). False uses the AWS default group."
  type        = bool
  default     = true
}
