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
      version = "~> 5.35"
    }

    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.1"
    }
  }

  required_version = "~> 1.6.0"
}

provider "aws" {
  region = "ap-northeast-2"
}

provider "cloudflare" {
}
