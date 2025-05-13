terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0" # Specify a recent version of the AWS provider
    }
  }

  # backend "s3" {
  #   bucket         = "your-terraform-state-bucket-name" # Replace with your S3 bucket name
  #   key            = "gitlab-poc/terraform.tfstate"
  #   region         = "us-east-1" # Replace with your S3 bucket region
  #   encrypt        = true
  #   # dynamodb_table = "your-terraform-state-lock-table" # Optional: for state locking
  #   # profile        = "your-aws-profile" # Optional: if not using default AWS profile
  # }
}

provider "aws" {
  region = var.aws_region
  # profile = "your-aws-profile" # Optional: Specify AWS profile if not using default or environment variables

  default_tags {
    tags = var.tags
  }
}
