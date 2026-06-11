terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  backend "s3" {
    bucket         = "localhelp-remote-state-terraform"
    key            = "localhelp-infra-dev/app-alb/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "s3-bucket-state-lock"
  }
}

# Configure the AWS Provider
#provide authentication here
provider "aws" {
  region = "us-east-1"
}