locals {
  rds_instances = toset(["auth", "flags", "targeting"])
}

resource "aws_security_group" "rds" {
  name   = "${var.project_name}-rds"
  vpc_id = var.vpc_id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [var.security_group_id]
  }
}

resource "aws_db_subnet_group" "this" {
  name       = var.project_name
  subnet_ids = var.subnet_ids
}

resource "random_password" "rds" {
  for_each = local.rds_instances

  length  = 24
  special = false
}

resource "aws_db_instance" "this" {
  for_each = local.rds_instances

  identifier             = "${var.project_name}-${each.key}"
  engine                 = "postgres"
  engine_version         = "16"
  instance_class         = "db.t4g.micro"
  allocated_storage      = 20
  storage_type           = "gp3"
  db_name                = each.key
  username               = "toggle"
  password               = random_password.rds[each.key].result
  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  skip_final_snapshot    = true
}

resource "aws_security_group" "redis" {
  name   = "${var.project_name}-redis"
  vpc_id = var.vpc_id

  ingress {
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [var.security_group_id]
  }
}

resource "aws_elasticache_subnet_group" "this" {
  name       = var.project_name
  subnet_ids = var.subnet_ids
}

resource "aws_elasticache_cluster" "this" {
  cluster_id         = var.project_name
  engine             = "redis"
  engine_version     = "7.1"
  node_type          = "cache.t4g.micro"
  num_cache_nodes    = 1
  subnet_group_name  = aws_elasticache_subnet_group.this.name
  security_group_ids = [aws_security_group.redis.id]
}

resource "aws_dynamodb_table" "analytics" {
  name         = "ToggleMasterAnalytics"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "event_id"

  attribute {
    name = "event_id"
    type = "S"
  }
}
