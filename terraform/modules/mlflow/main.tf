variable "domain_id" {
  type = string
}
variable "owner_name" {
  type = string
}
variable "execution_role_arn" {
  type = string
}

# S3 bucket for MLflow artifacts
resource "aws_s3_bucket" "mlflow_bucket" {
  bucket = "sagemaker-mlflow-${data.aws_caller_identity.current.account_id}"
}

data "aws_caller_identity" "current" {}

# Space for MLflow
resource "aws_sagemaker_space" "mlflow" {
  domain_id = var.domain_id

  ownership_settings {
    owner_user_profile_name = var.owner_name
  }

  space_display_name = "mlflow-space"
  space_name         = "mlflow-space"

  space_settings {
    app_type = "CodeEditor"

    code_editor_app_settings {
      default_resource_spec {
        instance_type = "ml.m5.xlarge"
      }
    }

    space_storage_settings {
      ebs_storage_settings {
        ebs_volume_size_in_gb = 100
      }
    }
  }

  space_sharing_settings {
    sharing_type = "Private"
  }
}

# Output values
output "mlflow_space_name" {
  value = aws_sagemaker_space.mlflow.space_name
}

output "mlflow_bucket" {
  value = aws_s3_bucket.mlflow_bucket.bucket
}
