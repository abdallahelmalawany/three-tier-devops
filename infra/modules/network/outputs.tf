output "vpc_id" {
  description = "ID of the VPC."
  value       = aws_vpc.this.id
}

output "public_subnet_ids" {
  description = "Public subnets (ALB, and ECS tasks when NAT is disabled)."
  value       = aws_subnet.public[*].id
}

output "app_subnet_ids" {
  description = "Private application subnets (ECS tasks when NAT is enabled)."
  value       = aws_subnet.app[*].id
}

output "data_subnet_ids" {
  description = "Isolated data subnets (RDS) with no internet route."
  value       = aws_subnet.data[*].id
}

output "nat_gateway_enabled" {
  description = "Whether private subnets have outbound internet access through NAT."
  value       = var.enable_nat_gateway
}
