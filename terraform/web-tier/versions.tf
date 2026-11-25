terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Optional but recommended: keep the state in your S3 bucket instead of on this laptop.
  # Fill in your bucket name, remove the leading "#" on each line, then run: terraform init -migrate-state
  # backend "s3" {
  #   bucket = "<your-state-bucket>"
  #   key    = "food-delivery/web-tier/terraform.tfstate"
  #   region = "ap-south-1"
  # }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Project   = "food-delivery"
      Owner     = var.owner
      ManagedBy = "terraform"
    }
  }
}

data "aws_caller_identity" "current" {}
