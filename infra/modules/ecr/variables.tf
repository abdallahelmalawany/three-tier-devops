variable "name_prefix" {
  description = "Prefix for repository names; repositories are created as <name_prefix>/<name>."
  type        = string
}

variable "repositories" {
  description = "Short names of the repositories to create, e.g. [\"backend\", \"frontend\"]."
  type        = list(string)
}

variable "max_image_count" {
  description = "Number of images to retain per repository."
  type        = number
  default     = 10
}

variable "force_delete" {
  description = "Allow terraform destroy to delete repositories that still contain images."
  type        = bool
  default     = false
}
