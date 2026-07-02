terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0" # Restricts updates to minor versions only
    }
  }
}

provider "aws" {
  region = "us-east-1"
}