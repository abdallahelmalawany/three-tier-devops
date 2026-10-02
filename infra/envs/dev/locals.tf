locals {
  # Naming convention: <project>-<environment>-<component>
  #   e.g. threetier-dev-alb, threetier-dev-backend, threetier-dev-postgres
  name_prefix = "${var.project}-${var.environment}"

  common_tags = {
    Project     = var.project
    Environment = var.environment
    Owner       = var.owner
    CostCenter  = var.cost_center
    ManagedBy   = "terraform"
    Repository  = var.github_repository
  }

  services = ["backend", "frontend"]
}
