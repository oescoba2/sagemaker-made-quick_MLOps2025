variable "domain_id" {
  type = string
}
variable "user_prefix" {
  type = string
}
variable "execution_role_arn" {
  type = string
}

# -----------------------------------------------------------
# Lifecycle Configuration — clones the GitHub repo on startup
# -----------------------------------------------------------
resource "aws_sagemaker_studio_lifecycle_config" "clone_repo" {
  studio_lifecycle_config_name     = "clone-repo"
  studio_lifecycle_config_app_type = "JupyterLab"

  # Base64-encode the lifecycle script explicitly
  studio_lifecycle_config_content = base64encode(<<-EOF
    #!/bin/bash
    set -ex

    if [ ! -z "$${SM_JOB_DEF_VERSION}" ]
    then
       echo "Running in job mode, skipping lifecycle config"
    else
       if [ ! -d "/home/sagemaker-user/amazon-sagemaker-from-idea-to-production" ]; then
         git clone https://github.com/aws-samples/amazon-sagemaker-from-idea-to-production.git || {
           echo "Error: Failed to clone repository"
           exit 0
         }
         echo "Repository successfully cloned"
       else
         echo "Repository already exists, skipping clone"
       fi
    fi
  EOF
  )
}




# -----------------------------------------------------------
# User Profile — attaches execution role, attaches lifecycle config
# -----------------------------------------------------------
resource "aws_sagemaker_user_profile" "studio_user" {
  domain_id         = var.domain_id
  user_profile_name = "${var.user_prefix}-${formatdate("YYYYMMDD'T'HHmmss", timestamp())}"

  user_settings {
    execution_role = var.execution_role_arn
    default_landing_uri = "studio::"

    jupyter_lab_app_settings {
      default_resource_spec {
        lifecycle_config_arn = aws_sagemaker_studio_lifecycle_config.clone_repo.arn
      }
      lifecycle_config_arns = [aws_sagemaker_studio_lifecycle_config.clone_repo.arn]
    }
  }
}

output "user_profile_name" {
  value = aws_sagemaker_user_profile.studio_user.user_profile_name
}

output "lifecycle_config_arn" {
  value = aws_sagemaker_studio_lifecycle_config.clone_repo.arn
}
