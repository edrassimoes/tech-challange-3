output "database_urls" {
  value = {
    for name, db in aws_db_instance.this :
    name => "postgres://${db.username}:${random_password.rds[name].result}@${db.endpoint}/${db.db_name}"
  }
  sensitive = true
}

output "redis_url" {
  value = "redis://${aws_elasticache_cluster.this.cache_nodes[0].address}:6379"
}

output "dynamodb_table_arn" {
  value = aws_dynamodb_table.analytics.arn
}
