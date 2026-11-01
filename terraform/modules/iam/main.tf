locals {
  service_roles = {
    ToggleMasterEvaluationServiceRole = {
      service_account = "evaluation:evaluation-service"
      statements = [{
        Effect   = "Allow"
        Action   = ["sqs:SendMessage"]
        Resource = var.queue_arn
      }]
    }
    ToggleMasterAnalyticsServiceRole = {
      service_account = "analytics:analytics-service"
      statements = [
        {
          Effect   = "Allow"
          Action   = ["sqs:ReceiveMessage", "sqs:DeleteMessage", "sqs:GetQueueAttributes"]
          Resource = var.queue_arn
        },
        {
          Effect   = "Allow"
          Action   = ["dynamodb:PutItem"]
          Resource = var.table_arn
        },
      ]
    }
    ToggleMasterKedaRole = {
      service_account = "keda:keda-operator"
      statements = [{
        Effect   = "Allow"
        Action   = ["sqs:GetQueueAttributes"]
        Resource = var.queue_arn
      }]
    }
  }
}

resource "aws_iam_role" "service" {
  for_each = local.service_roles

  name = each.key

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Action    = "sts:AssumeRoleWithWebIdentity"
      Principal = { Federated = var.oidc_provider_arn }
      Condition = {
        StringEquals = {
          "${var.oidc_issuer}:aud" = "sts.amazonaws.com"
          "${var.oidc_issuer}:sub" = "system:serviceaccount:${each.value.service_account}"
        }
      }
    }]
  })
}

resource "aws_iam_role_policy" "service" {
  for_each = local.service_roles

  name = each.key
  role = aws_iam_role.service[each.key].id

  policy = jsonencode({
    Version   = "2012-10-17"
    Statement = each.value.statements
  })
}

resource "aws_iam_openid_connect_provider" "github" {
  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]
}

resource "aws_iam_role" "github_actions" {
  name = "ToggleMasterGitHubActionsRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Action    = "sts:AssumeRoleWithWebIdentity"
      Principal = { Federated = aws_iam_openid_connect_provider.github.arn }
      Condition = {
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          "token.actions.githubusercontent.com:sub" = "repo:${var.github_repository}:ref:refs/heads/main"
        }
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "github_actions" {
  role       = aws_iam_role.github_actions.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser"
}
