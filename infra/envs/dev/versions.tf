terraform {
  required_version = ">= 1.11.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.7"
    }
  }

  # Partial configuration: bucket/key/region are supplied at init time with
  # `terraform init -backend-config=backend.hcl` (see backend.hcl.example).
  backend "s3" {}
}
