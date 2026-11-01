resource "aws_ecr_repository" "this" {
  for_each = toset([
    "auth-service",
    "flag-service",
    "targeting-service",
    "evaluation-service",
    "analytics-service",
  ])

  name         = each.value
  force_delete = true
}
