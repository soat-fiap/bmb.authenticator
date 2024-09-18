terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~>5.64.0"
    }
  }
  required_version = "~>1.9.4"
}

provider "aws" {
  region = var.region
  alias  = "us-east-1"
}