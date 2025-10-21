terraform {
  backend "s3" {
    bucket  = "mlopsf2025" # TODO: replace with your bucket name
    key     = "terraform/sagemaker-domain.tfstate"
    region  = "us-east-1"
    encrypt = true
  }
}
