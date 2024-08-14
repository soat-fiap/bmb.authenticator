terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~>5.62.0"
    }
  }
  required_version = "~>1.9.4"
}

provider "aws" {
  profile = var.profile
  region  = var.region
  alias   = "us-east-1"
}