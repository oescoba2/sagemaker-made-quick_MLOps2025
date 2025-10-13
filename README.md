# sagemaker-made-quick-tutorial
This is a terraform and github actions wrapper on ["Amazon SageMaker AI MLOps: from idea to production in six steps"](https://github.com/aws-samples/amazon-sagemaker-from-idea-to-production) to make it easier to deploy and tear down. It uses github actions to run terraform to deploy or teardown the AWS resources automatically.

<br>

<img width="1280" height="720" alt="Sagemaker-Made-Quick(1)" src="https://github.com/user-attachments/assets/a6f615d6-0531-4261-b613-4416c4db341b" />

<br>

## Contents

[Prerequisites](#Prerequisites-to-run)

[Setup Instructions](#Setup-Instructions)

[Deploying](#Deploying-the-AWS-Infrastructure)

[Destroying](#Destroying-the-AWS-Infrastructure)

<br>

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
    - `sagemaker:CreateDomain` [(see below on instructions to make)](#Create-Custom-Policy-for-Advanced-SageMaker-Domain-Control)

- An AWS S3 bucket
- Fork this repo to your own github account. Note this repo assumes an AWS region of `us-east-1`.
- A Github PAT Token (Classic)

<br>

## Setup Instructions
## Adding your Github PAT Token

Click your Github profile in the top right at Github.com


Click `Settings` > `Developer Settings` > `Personal Access Tokens` > `Tokens (Classic)` > `Generate New Token` > `Generate New Token (Classic)`

Give it workflow permissions

<br> 

<img width="802" height="773" alt="image" src="https://github.com/user-attachments/assets/fab80ef2-0ee5-40f2-9846-5b123d428577" />

<br>

Once the token is created, copy the token and return to your branch's repository page

From your repo page, go to the top and click `Settings` > `Secrets & Variables` > `Actions` > `New Repository Secret`

Name the secret `PAT_TOKEN`

<br>

<img width="789" height="441" alt="image" src="https://github.com/user-attachments/assets/a6aa8ac7-cea8-469e-9056-d63c97904152" />

<br>

The Personal Access Token is now available to the actions workflows

<br>

## Creating the IAM user

We first need an IAM user to give Github and Terraform access to controlling resources on our AWS account. It will need pretty broad privileges to be able to provision all of the infrastructure for the lab.

Go to IAM > Users > Create User
Give it a name
<img width="1402" height="446" alt="image" src="https://github.com/user-attachments/assets/11f70b9c-a08b-4b80-b42a-b560ff9c425d" />

Attach the following policies
<img width="1391" height="637" alt="image" src="https://github.com/user-attachments/assets/56d0b7fa-818e-46b1-8532-eb3816ca3dca" />
- `AmazonEC2FullAccess`
- `AmazonS3FullAccess`
- `AmazonSageMakerAdmin-ServiceCatalogProductsServiceRolePolicy`
- `AmazonSageMakerFullAccess`
- `AmazonSageMakerPipelinesIntegrations`
- `AWSCloudFormationFullAccess`
- `AWSCodePipeline_FullAccess`
- `AWSCodeStarFullAccess`
- `IAMFullAccess`
- `sagemaker:CreateDomain` [(see below on instructions to make)](#Create-Custom-Policy-for-Advanced-SageMaker-Domain-Control)

Click `Create user`

<br>

### Create Custom Policy for Advanced SageMaker Domain Control

The default policies, including AmazonSageMakerFullAccess, do not give Sagemaker Domain create and delete privileges so we need to make a custom policy that does.

Go to IAM > Policies > Create Policy

Click `JSON` and paste this in:
```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "SageMakerDomainProvisioning",
            "Effect": "Allow",
            "Action": [
                "sagemaker:CreateDomain",
                "sagemaker:DeleteDomain",
                "sagemaker:DescribeDomain",
                "sagemaker:ListDomains",
                "sagemaker:CreateUserProfile",
                "sagemaker:DeleteUserProfile",
                "sagemaker:DescribeUserProfile",
                "sagemaker:CreateSpace",
                "sagemaker:DeleteSpace",
                "sagemaker:DescribeSpace",
                "sagemaker:CreateApp",
                "sagemaker:DeleteApp",
                "sagemaker:DescribeApp",
                "sagemaker:CreateStudioLifecycleConfig",
                "sagemaker:DeleteStudioLifecycleConfig",
                "sagemaker:DescribeStudioLifecycleConfig",
                "sagemaker:UpdateDomain",
                "sagemaker:UpdateUserProfile",
                "sagemaker:List*",
                "servicecatalog:*",
                "iam:PassRole",
                "ec2:Describe*",
                "s3:*"
            ],
            "Resource": "*"
        }
    ]
}
```
<img width="1622" height="841" alt="image" src="https://github.com/user-attachments/assets/d5e29fa3-3dab-4fd6-b290-239c9cf85d0c" />

Click Next and give the Policy a name and Description

Click `Create policy`

<br>

### Add the custom policy to your user

Go to IAM > Users > [YOUR_NEW_USER's_NAME]

Hit `Add Permissions` > `Add Permissions`

Click `Attach policies directly`

Search for and add your custom policy to the user

<img width="1484" height="847" alt="image" src="https://github.com/user-attachments/assets/e8d9ee2d-aa47-4474-9003-6ddb76769bc9" />

<br>
<br>

## Create an access key for the user

The access key will let Github use the IAM user. We will load the access key ID and secret into the github actions environment where our actions workflows and terraform will be able to use it. The same access key can also be used on a local machine to use terraform locally.

Go to IAM > USERS > [YOUR_NEW_USER's_NAME]

Click `Security Credentials`

Click `Create access key`

Follow the pictures:
<img width="971" height="716" alt="image" src="https://github.com/user-attachments/assets/7601ba71-e417-47f1-b402-65ee5d3ab460" />
<img width="979" height="260" alt="image" src="https://github.com/user-attachments/assets/2c425b03-3234-4728-9a51-f3d37b2594bb" />
Copy the key ID and Secret Access Key

<br>

## Input the access key into your forked repository

Go to the page for your forked repository (https://github.com/<YOUR_GITHUB_USER>/sagemaker-made-quick)

Click `Settings` > `Secrets and variables` > `Actions`

Click `New repository secret`

For the Access Key ID:
- Name: AWS_ACCESS_KEY_ID
- Secret: Paste your access_key_id

For the Access Key Secret:
- Name: AWS_SECRET_ACCESS_KEY
- Secret: Paste your secret


<img width="799" height="199" alt="image" src="https://github.com/user-attachments/assets/7e88cde3-38d1-4a88-b7f9-63125195ed69" />

These are the default values that Terraform looks for when getting auth for AWS. You can also set these on your local machine if you want to use Terraform there.

<br>

## Create an S3 Bucket

Terraform will need a place to store its current state in a file called `terraform.tfstate`. We will make an S3 bucket for it to use. This will make sure there is a central place that our local machine and github can both use to retrieve the current terraform state.

Go to `S3` > `Create Bucket`

The default settings are probably fine. Click `Create bucket` after giving it a unique name.

<br>

## Update your forked repository's code
In your forked repository, update the file at

`/terraform/modules/user/main.tf`

Around line 45 there should be a url for this repository, update it to be for your own forked repository

<br>

<img width="739" height="230" alt="image" src="https://github.com/user-attachments/assets/e882a040-b60a-4064-8aec-73207c63c052" />

<br>

Update the bucket name to be your S3 Bucket's unique name

<br>

<img width="708" height="294" alt="image" src="https://github.com/user-attachments/assets/26d6a028-9264-4abf-a387-fcdaa5448fb6" />

<br>

After these steps, your forked repository is ready to provision your resources in AWS and track your progress.

<br>

## Deploying the AWS Infrastructure
In your forked repository's page, navigate to `Actions` > `Terraform Workflow` > `Run Workflow` > `Run Workflow`

This will start the workflow for deploying the infrastructure and refreshing the page will show the status of the running workflow. It will take about 3 minutes to deploy everything.

<br>

<img width="1911" height="906" alt="image" src="https://github.com/user-attachments/assets/6b50a4b7-fdf3-4095-be9d-a386ac27ec79" />

<br>

## Destroying the AWS Infrastructure

> [!WARNING]
> For Terraform to be able to destroy the domain we need to make sure that all the apps and spaces in the domain are deleted and not running. Terraform does not manage those resources.


In JupyterLab stop any running spaces

<br>

<img width="1643" height="914" alt="image" src="https://github.com/user-attachments/assets/e4b8ca86-4097-46a3-b9d2-c755ea3e639b" />

<br>

<img width="1643" height="914" alt="image" src="https://github.com/user-attachments/assets/39880a59-35a5-44ba-9304-643cd0a6bbd6" />

<br>

Once everything is stopped in JupyterLab we can go to the repository's page then:

`Actions` > `Terraform Workflow` > `Run Workflow` > `destroy` > `Run Workflow`

<br>

<img width="399" height="381" alt="image" src="https://github.com/user-attachments/assets/55abc776-6bc5-41e3-81b2-9402624d2053" />

<br>

Make sure this workflow finishes successfully or you will still have resources in AWS collecting costs
