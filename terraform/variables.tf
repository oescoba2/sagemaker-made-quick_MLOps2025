variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "domain_prefix" {
  type    = string
  default = "mlops-workshop-domain"
}

variable "user_prefix" {
  type    = string
  default = "studio-user"
}

variable "spaces_enabled" {
  type    = bool
  default = true
}
