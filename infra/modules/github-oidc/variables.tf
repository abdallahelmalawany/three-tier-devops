variable "name_prefix" {
  description = "Prefix for all resource names."
  type        = string
}

variable "github_repository" {
  description = "Repository allowed to assume the role, as owner/name."
  type        = string

  validation {
    condition     = can(regex("^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$", var.github_repository))
    error_message = "github_repository must look like owner/name."
  }
}

variable "branch" {
  description = "Branch allowed to deploy."
  type        = string
  default     = "main"
}

variable "environment" {
  description = "GitHub deployment environment allowed to deploy."
  type        = string
}

variable "create_oidc_provider" {
  description = "Create the GitHub OIDC provider. Set false if the account already has one (only one per account is allowed)."
  type        = bool
  default     = true
}

variable "ecr_repository_arns" {
  description = "Repositories the pipeline may push to."
  type        = list(string)
}

variable "ecs_service_arns" {
  description = "Services the pipeline may update."
  type        = list(string)
}

variable "passable_role_arns" {
  description = "Task / execution roles the pipeline may reference in new task definitions."
  type        = list(string)
}
