terraform {
  cloud {
    organization = "bacchus-snu"

    workspaces {
      name = "infra"
    }
  }

  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5.28"
    }
  }

  required_version = "~> 1.16.0"
}
