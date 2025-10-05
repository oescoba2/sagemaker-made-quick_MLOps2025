variable "domain_prefix" {
  type = string
}
variable "vpc_id" {
  type = string
}
variable "subnet_ids" {
  type = list(string)
}
variable "execution_role_arn" {
  type = string
}

resource "aws_s3_bucket" "studio_bucket" {
  bucket = "sagemaker-studio-${data.aws_caller_identity.current.account_id}"
}

data "aws_caller_identity" "current" {}

resource "aws_sagemaker_domain" "studio" {
  domain_name = "${var.domain_prefix}-${formatdate("YYYYMMDD'T'HHmmss", timestamp())}"
  auth_mode   = "IAM"

  vpc_id     = var.vpc_id
  subnet_ids = var.subnet_ids

  app_network_access_type = "PublicInternetOnly"

  domain_settings {
    docker_settings {
      enable_docker_access = "ENABLED"
    }
  }

  default_user_settings {
    execution_role = var.execution_role_arn
    default_landing_uri = "studio::"
    studio_web_portal_settings {
      hidden_app_types = ["JupyterServer"]
    }
    canvas_app_settings {
      workspace_settings {
        s3_artifact_path = "s3://${aws_s3_bucket.studio_bucket.bucket}/"
      }
      time_series_forecasting_settings { status = "ENABLED" }
      model_register_settings          { status = "ENABLED" }
      direct_deploy_settings           { status = "ENABLED" }
      kendra_settings                  { status = "DISABLED" }
      generative_ai_settings {
        amazon_bedrock_role_arn = var.execution_role_arn
      }
    }
  }

  default_space_settings {
    execution_role = var.execution_role_arn
  }
}

output "domain_id" {
  value = aws_sagemaker_domain.studio.id
}

output "domain_name" {
  value = aws_sagemaker_domain.studio.domain_name
}

output "bucket_name" {
  value = aws_s3_bucket.studio_bucket.bucket
}
