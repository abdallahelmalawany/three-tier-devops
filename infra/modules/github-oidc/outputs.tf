output "role_arn" {
  description = "Role ARN to store as the AWS_DEPLOY_ROLE_ARN GitHub variable."
  value       = aws_iam_role.deploy.arn
}
