# sagemaker-made-easier
This is a terraform and github actions wrapper on ["Amazon SageMaker AI MLOps: from idea to production in six steps"](https://github.com/aws-samples/amazon-sagemaker-from-idea-to-production) to make it easier to deploy and tear down.

## Prerequisites to run
- An AWS IAM user with the following policies:
    - `AmazonEC2FullAccess`
    - `AmazonS3FullAccess`
    - `AmazonSageMakerAdmin-ServiceCatalogProductsServiceRolePolicy`
    - `AmazonSageMakerFullAccess`
    - `AmazonSageMakerPipelinesIntegrations`
    - `AWSCloudFormationFullAccess`
    - `AWSCodePipeline_FullAccess`
    - `AWSCodeStarFullAccess`
    - `IAMFullAccess`
    - `sagemaker:CreateDomain`

- An AWS S3 bucket
- Fork this repo and change all the variables in `variables.tf` to your own values. Note this repo assumes an AWS region of `us-east-1`.


