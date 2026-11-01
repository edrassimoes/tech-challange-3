output "service_role_arns" {
  value = { for name, role in aws_iam_role.service : name => role.arn }
}

output "github_actions_role_arn" {
  value = aws_iam_role.github_actions.arn
}
