terraform {
  required_version = "~> 1.10"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.18"
    }

    cloudinit = {
      source  = "hashicorp/cloudinit"
      version = "~> 2.3"
    }
  }

  backend "s3" {
    region       = "ap-northeast-1"
    bucket       = "devops-nixos-demo-terraform-state"
    use_lockfile = true
    key          = "global/control-plane/terraform.tfstate"
    encrypt      = true
  }
}

provider "aws" {
  region = "ap-northeast-1"
}
