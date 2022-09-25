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
      version = "~> 4.32"
    }

    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 3.14"
    }
  }

  required_version = ">= 0.14.9"
}

provider "aws" {
  region = "ap-northeast-2"
}

provider "cloudflare" {
}
