output "repository_urls" {
  description = "Map of short name => repository URL."
  value       = { for name, repo in aws_ecr_repository.this : name => repo.repository_url }
}

output "repository_arns" {
  description = "Map of short name => repository ARN."
  value       = { for name, repo in aws_ecr_repository.this : name => repo.arn }
}
