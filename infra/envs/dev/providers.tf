provider "aws" {
  region = var.aws_region

  # Every taggable resource gets the standard tag set automatically.
  default_tags {
    tags = local.common_tags
  }
}

# Same account and region, used only for IAM policies: some sandboxes deny
# iam:TagPolicy, so their tags can be switched off with tag_iam_policies.
provider "aws" {
  alias  = "iam_policy"
  region = var.aws_region

  default_tags {
    tags = var.tag_iam_policies ? local.common_tags : {}
  }
}
