module "network" {
  source = "./modules/network"

  project_name = var.project_name
  azs          = ["${var.region}a", "${var.region}b"]
}

module "eks" {
  source = "./modules/eks"

  cluster_name = "${var.project_name}-cluster"
  subnet_ids   = module.network.public_subnet_ids
}

module "databases" {
  source = "./modules/databases"

  project_name      = var.project_name
  vpc_id            = module.network.vpc_id
  subnet_ids        = module.network.private_subnet_ids
  security_group_id = module.eks.cluster_security_group_id
}

module "messaging" {
  source = "./modules/messaging"
}

module "ecr" {
  source = "./modules/ecr"
}

module "iam" {
  source = "./modules/iam"

  oidc_provider_arn = module.eks.oidc_provider_arn
  oidc_issuer       = module.eks.oidc_issuer
  queue_arn         = module.messaging.queue_arn
  table_arn         = module.databases.dynamodb_table_arn
  github_repository = var.github_repository
}
