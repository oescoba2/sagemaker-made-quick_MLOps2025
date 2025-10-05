variable "domain_id" {
  type = string
}
variable "owner_name" {
  type = string
}
variable "execution_role_arn" {
  type = string
}

# JupyterLab space
resource "aws_sagemaker_space" "jupyterlab" {
  domain_id = var.domain_id

  ownership_settings {
    owner_user_profile_name = var.owner_name
  }

  space_display_name = "jupyterlab-space"
  space_name         = "jupyterlab-space"

  space_settings {
    app_type = "JupyterLab"

    jupyter_lab_app_settings {
      default_resource_spec {
        instance_type = "ml.m5.2xlarge"
      }
    }


    space_storage_settings {
      ebs_storage_settings {
        ebs_volume_size_in_gb = 50
      }
    }
  }

  space_sharing_settings {
    sharing_type = "Private"
  }
}

# CodeEditor space
resource "aws_sagemaker_space" "codeeditor" {
  domain_id = var.domain_id

  ownership_settings {
    owner_user_profile_name = var.owner_name
  }

  space_display_name = "codeeditor-space"
  space_name         = "codeeditor-space"

  space_settings {
    app_type = "CodeEditor"

    code_editor_app_settings {
      default_resource_spec {
        instance_type = "ml.t3.large"
      }
    }

    space_storage_settings {
      ebs_storage_settings {
        ebs_volume_size_in_gb = 50
      }
    }
  }

  space_sharing_settings {
    sharing_type = "Private"
  }
}
