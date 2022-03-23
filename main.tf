variable "aws_access_key_id" {
  description = "Access Key ID"
  type        = string
}

variable "aws_secret_access_key" {
  description = "Secret Access Key"
  type        = string
  sensitive   = true
}

terraform {
  cloud {
    organization = "bacchus-snu"

    workspaces {
      name = "infra"
    }
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27"
    }
  }

  required_version = ">= 0.14.9"
}

provider "aws" {
  region     = "ap-northeast-2"
  access_key = var.aws_access_key_id
  secret_key = var.aws_secret_access_key
}

resource "aws_instance" "bacchus_app_server" {
  ami           = "ami-0b4a713d12660d96c"
  instance_type = "t2.micro"

  tags = {
    Name = "ExampleAppServerInstance"
  }
}
