# Imports the four EXISTING servers into Terraform. It does not create new ones.
# Corrected version of Prabha's file. Read the notes marked CHANGED.
#
# RULE: run "terraform plan" first. Do NOT run "terraform apply" if the plan contains
#       the words "must be replaced" or "destroy".

terraform {
  required_version = ">= 1.7.0" # CHANGED: the import block with for_each needs 1.7 or newer

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # CHANGED: keep the state in S3, not on one laptop. Fill in the bucket, remove the "#"s,
  # then run: terraform init
  # backend "s3" {
  #   bucket = "<your-state-bucket>"
  #   key    = "food-delivery/imported-servers/terraform.tfstate"
  #   region = "ap-south-1"
  # }
}

provider "aws" {
  region = "ap-south-1"
}

variable "key_name" {
  type    = string
  default = "food-key"
}

# CHANGED: removed the unused vpc_id variable

locals {
  instances = {
    food-agent = {
      instance_id         = "i-047b902a612e2db51"
      instance_type       = "m7i-flex.large"
      ami                 = "ami-0c7632fb77f35db43"
      subnet_id           = "subnet-0cadb8b183e331a2c"
      security_group_id   = "sg-084b1c813f1af98ff"
      volume_size         = 40
      termination_protect = false
    }
    food-controller = {
      instance_id         = "i-0453ca6d926de6b2e"
      instance_type       = "t3.small"
      ami                 = "ami-0c7632fb77f35db43"
      subnet_id           = "subnet-0922b02c338363fbf"
      security_group_id   = "sg-00bb1b684e4544a3a"
      volume_size         = 25
      termination_protect = true # you turned this on for the controller
    }
    food-app = {
      instance_id         = "i-09a752b2d82dcf145"
      instance_type       = "t3.small"
      ami                 = "ami-0c7632fb77f35db43"
      subnet_id           = "subnet-0922b02c338363fbf"
      security_group_id   = "sg-0c60d2b720227c4b2"
      volume_size         = 20
      termination_protect = true # and for the app server
    }
    food-monitor = {
      instance_id         = "i-095c8a5c8e8eebe93"
      instance_type       = "t3.small"
      ami                 = "ami-0c7632fb77f35db43"
      subnet_id           = "subnet-0922b02c338363fbf"
      security_group_id   = "sg-0d0f64566708343b1"
      volume_size         = 20
      termination_protect = false
    }
  }
}

resource "aws_instance" "food" {
  for_each = local.instances

  ami                     = each.value.ami
  instance_type           = each.value.instance_type
  subnet_id               = each.value.subnet_id
  vpc_security_group_ids  = [each.value.security_group_id]
  key_name                = var.key_name
  disable_api_termination = each.value.termination_protect # CHANGED: matches what is set in AWS

  root_block_device {
    volume_type           = "gp3"
    volume_size           = each.value.volume_size
    delete_on_termination = true
    encrypted             = true
  }

  tags = {
    Name = each.key
  }

  lifecycle {
    prevent_destroy = true # CHANGED: Terraform refuses to delete these servers

    # CHANGED: also ignore tags, so the Owner and Project tags you added by hand are not removed.
    # Later, copy the real tags into the "tags" block above and remove "tags" from this list.
    ignore_changes = [ami, user_data, tags, tags_all, root_block_device[0].encrypted]
  }
}

# Imports the existing servers (needs Terraform 1.7 or newer).
# Once "terraform apply" has recorded them, this block can be removed.
import {
  for_each = local.instances
  to       = aws_instance.food[each.key]
  id       = each.value.instance_id
}

output "private_ips" {
  value = { for k, v in aws_instance.food : k => v.private_ip }
}

output "public_ips" {
  value = { for k, v in aws_instance.food : k => v.public_ip }
}

output "instance_ids" {
  value = { for k, v in aws_instance.food : k => v.id }
}
