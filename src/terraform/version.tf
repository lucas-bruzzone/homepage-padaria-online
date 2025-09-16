terraform {
  backend "s3" {
    # Substitua pelos seus valores
    bucket         = "padaria-online-terraform"
    key            = "padaria-online-terraform/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-lock-state"
    encrypt        = true
  }


  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = var.environment
      Project     = var.project_name
      ManagedBy   = "terraform"
      Repository  = "REPO_NAME"
    }
  }
}