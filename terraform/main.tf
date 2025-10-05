provider "aws" {
  region = var.aws_region
}

# Get AWS account ID
data "aws_caller_identity" "current" {}

# Get Default VPC and Subnets
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# ----------------------------
# IAM Role Module
# ----------------------------
module "iam" {
  source     = "./modules/iam"
  account_id = data.aws_caller_identity.current.account_id
}

# ----------------------------
# SageMaker Domain Module
# ----------------------------
module "domain" {
  source = "./modules/domain"

  domain_prefix      = var.domain_prefix
  vpc_id             = data.aws_vpc.default.id
  subnet_ids         = data.aws_subnets.default.ids
  execution_role_arn = module.iam.execution_role_arn
}

# ----------------------------
# User Profile Module
# ----------------------------
module "user" {
  source = "./modules/user"

  domain_id          = module.domain.domain_id
  user_prefix        = var.user_prefix
  execution_role_arn = module.iam.execution_role_arn
}

# ----------------------------
# Spaces Module
# ----------------------------
module "spaces" {
  source = "./modules/spaces"
  count  = var.spaces_enabled ? 1 : 0

  domain_id          = module.domain.domain_id
  owner_name         = module.user.user_profile_name
  execution_role_arn = module.iam.execution_role_arn
}


# ----------------------------
# MLflow Module
# ----------------------------
module "mlflow" {
  source = "./modules/mlflow"

  domain_id          = module.domain.domain_id
  owner_name         = module.user.user_profile_name
  execution_role_arn = module.iam.execution_role_arn
}

