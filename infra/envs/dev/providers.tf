provider "aws" {
  region = var.aws_region

  # Every taggable resource gets the standard tag set automatically.
  default_tags {
    tags = local.common_tags
  }
}
