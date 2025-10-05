terraform {
  backend "s3" {
    bucket  = "cs401rex" # TODO: replace with your bucket name
    key     = "terraform/sagemaker-domain.tfstate"
    region  = "us-east-1"
    encrypt = true
  }
}
