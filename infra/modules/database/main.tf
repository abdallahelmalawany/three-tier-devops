# The master password is generated with an *ephemeral* resource and passed to
# RDS and SSM through write-only arguments, so it is never stored in the
# Terraform plan or state file. The ECS task reads it from SSM at start-up.
ephemeral "random_password" "master" {
  length           = 32
  special          = true
  override_special = "!#$%^&*()-_=+[]{}<>:?" # RDS forbids / @ " and spaces
}

resource "aws_ssm_parameter" "master_password" {
  name             = "/${var.name_prefix}/database/master-password"
  description      = "Master password of ${var.name_prefix}-postgres"
  type             = "SecureString" # encrypted with the AWS-managed aws/ssm KMS key
  value_wo         = ephemeral.random_password.master.result
  value_wo_version = var.password_version
}

resource "aws_db_subnet_group" "this" {
  name        = "${var.name_prefix}-db-subnets"
  description = "Isolated data subnets for ${var.name_prefix}"
  subnet_ids  = var.subnet_ids
}

# Optional: some sandboxes deny rds:CreateDBParameterGroup. Without it the
# instance uses the AWS default group, which on PostgreSQL 15+ already sets
# rds.force_ssl = 1 (only the extra query/connection logging is lost).
resource "aws_db_parameter_group" "this" {
  count = var.create_parameter_group ? 1 : 0

  name        = "${var.name_prefix}-postgres${var.engine_major_version}"
  family      = "postgres${var.engine_major_version}"
  description = "Hardened parameters for ${var.name_prefix}"

  parameter {
    name  = "rds.force_ssl" # reject unencrypted client connections
    value = "1"
  }

  parameter {
    name  = "log_min_duration_statement" # log queries slower than 500 ms
    value = "500"
  }

  parameter {
    name  = "log_connections"
    value = "1"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_db_instance" "this" {
  identifier     = "${var.name_prefix}-postgres"
  engine         = "postgres"
  engine_version = var.engine_major_version
  instance_class = var.instance_class

  db_name             = var.database_name
  username            = var.master_username
  password_wo         = ephemeral.random_password.master.result
  password_wo_version = var.password_version
  port                = var.port

  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_type          = "gp3"
  storage_encrypted     = true # KMS encryption at rest (aws/rds key)

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [var.security_group_id]
  publicly_accessible    = false
  multi_az               = var.multi_az
  parameter_group_name   = var.create_parameter_group ? aws_db_parameter_group.this[0].name : null

  backup_retention_period         = var.backup_retention_days
  copy_tags_to_snapshot           = true
  enabled_cloudwatch_logs_exports = ["postgresql"]
  auto_minor_version_upgrade      = true
  apply_immediately               = var.apply_immediately

  deletion_protection       = var.deletion_protection
  skip_final_snapshot       = var.skip_final_snapshot
  final_snapshot_identifier = var.skip_final_snapshot ? null : "${var.name_prefix}-postgres-final"
}
