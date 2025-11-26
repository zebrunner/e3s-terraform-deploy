data "aws_secretsmanager_secret" "e3s_automatic_update_github_token" {
  count = var.automatic_update_enabled ? 1 : 0
  name  = var.automatic_update_github_credentials_secret_name
}

########################################################################################################################

resource "aws_codebuild_project" "automatic_update" {
  count        = var.automatic_update_enabled ? 1 : 0
  name         = local.e3s_codebuild_project_name
  service_role = aws_iam_role.codebuild[0].arn

  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/amazonlinux2-x86_64-standard:5.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"

    environment_variable {
      name  = "SNS_SECRET_ID"
      value = var.sns_topic_secret_name
    }
  }

  source {
    type     = "GITHUB"
    location = var.automatic_update_github_repo
    auth {
      type     = "SECRETS_MANAGER"
      resource = data.aws_secretsmanager_secret.e3s_automatic_update_github_token[0].arn
    }
    buildspec = templatefile(
      "./buildspec/automatic-update.yaml",
      {
        cluster_name                  = local.e3s_cluster_name
        region                        = var.region
        config_s3_tfbackend_secret_id = var.automatic_update_config_s3_tfbackend_secret_name
        terraform_tfvars_secret_id    = var.automatic_update_terraform_tfvars_secret_name
      }
    )
  }
  source_version = var.automatic_update_github_branch

  vpc_config {
    vpc_id             = var.vpc_id
    subnets            = [var.private_subnet_1_id, var.private_subnet_2_id]
    security_group_ids = [aws_security_group.codebuild[0].id]
  }

  logs_config {
    cloudwatch_logs {
      group_name = "/aws/codebuild/e3s-automatic-update"
    }
  }
}
