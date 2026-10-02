output "alb_security_group_id" {
  description = "Security group of the public load balancer."
  value       = aws_security_group.alb.id
}

output "backend_security_group_id" {
  description = "Security group of the backend tasks."
  value       = aws_security_group.backend.id
}

output "frontend_security_group_id" {
  description = "Security group of the frontend tasks."
  value       = aws_security_group.frontend.id
}

output "database_security_group_id" {
  description = "Security group of the RDS instance."
  value       = aws_security_group.database.id
}
