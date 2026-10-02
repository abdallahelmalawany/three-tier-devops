output "address" {
  description = "Hostname of the database endpoint."
  value       = aws_db_instance.this.address
}

output "port" {
  description = "Database port."
  value       = aws_db_instance.this.port
}

output "database_name" {
  description = "Application database name."
  value       = aws_db_instance.this.db_name
}

output "master_username" {
  description = "Master user name."
  value       = aws_db_instance.this.username
}

output "password_parameter_arn" {
  description = "ARN of the SSM SecureString parameter holding the master password."
  value       = aws_ssm_parameter.master_password.arn
}

output "instance_identifier" {
  description = "RDS instance identifier (CloudWatch dimension DBInstanceIdentifier)."
  value       = aws_db_instance.this.identifier
}
