variable "account_id" {
  type = string
}

resource "aws_iam_role" "sagemaker_exec" {
  name = "sagemaker-exec-${var.account_id}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = [
            "sagemaker.amazonaws.com",
            "events.amazonaws.com",
            "forecast.amazonaws.com",
            "lambda.amazonaws.com"
          ]
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# Attach key managed policies
locals {
  managed_policies = [
    "arn:aws:iam::aws:policy/AmazonSageMakerFullAccess",
    "arn:aws:iam::aws:policy/AmazonSageMakerCanvasFullAccess",
    "arn:aws:iam::aws:policy/AmazonSageMakerCanvasAIServicesAccess",
    "arn:aws:iam::aws:policy/AmazonS3FullAccess",
    "arn:aws:iam::aws:policy/AWSCodePipeline_FullAccess",
    "arn:aws:iam::aws:policy/AWSCodeStarFullAccess",
    "arn:aws:iam::aws:policy/AWSCloudFormationFullAccess",
    "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  ]
}

resource "aws_iam_role_policy_attachment" "attachments" {
  for_each   = toset(local.managed_policies)
  role       = aws_iam_role.sagemaker_exec.name
  policy_arn = each.value
}

output "execution_role_arn" {
  value = aws_iam_role.sagemaker_exec.arn
}
