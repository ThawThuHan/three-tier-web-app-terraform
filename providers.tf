terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.21.0"
    }
  }
}

provider "aws" {
  region     = var.region
  access_key = "AKIASS47AGXKR4DJJP55"
  secret_key = "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"
}