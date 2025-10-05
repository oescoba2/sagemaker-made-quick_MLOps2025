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

# MLflow S3 bucket permissions
resource "aws_iam_policy" "mlflow_bucket_policy" {
  name        = "mlflow-bucket-access"
  description = "Allow SageMaker apps to read/write MLflow artifacts"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:ListBucket",
          "s3:GetObject",
          "s3:PutObject"
        ],
        Resource = [
          "arn:aws:s3:::sagemaker-mlflow-${var.account_id}",
          "arn:aws:s3:::sagemaker-mlflow-${var.account_id}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "mlflow_bucket_access" {
  role       = aws_iam_role.sagemaker_exec.name
  policy_arn = aws_iam_policy.mlflow_bucket_policy.arn
}


# -----------------------------------------------------------
# MLflow API permissions
# -----------------------------------------------------------
resource "aws_iam_policy" "mlflow_api_policy" {
  name        = "mlflow-api-access"
  description = "Allow SageMaker execution role to use SageMaker MLflow tracking APIs"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "sagemaker-mlflow:*"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "mlflow_api_policy_attach" {
  role       = aws_iam_role.sagemaker_exec.name
  policy_arn = aws_iam_policy.mlflow_api_policy.arn
}
