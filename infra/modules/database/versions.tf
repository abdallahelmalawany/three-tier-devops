terraform {
  # 1.11+ for ephemeral resources and write-only arguments.
  required_version = ">= 1.11.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.7.0" # ephemeral random_password
    }
  }
}
