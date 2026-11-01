output "cluster_name" {
  value = module.eks.cluster_name
}

output "database_urls" {
  value     = module.databases.database_urls
  sensitive = true
}

output "redis_url" {
  value = module.databases.redis_url
}

output "sqs_queue_url" {
  value = module.messaging.queue_url
}

output "ecr_repository_urls" {
  value = module.ecr.repository_urls
}

output "service_role_arns" {
  value = module.iam.service_role_arns
}

output "github_actions_role_arn" {
  value = module.iam.github_actions_role_arn
}
