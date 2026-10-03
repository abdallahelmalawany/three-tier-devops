terraform {
  required_version = ">= 1.11.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0"
      # Used for IAM policies only, so their tags can be turned off where
      # iam:TagPolicy is denied.
      configuration_aliases = [aws.iam_policy]
    }
  }
}
