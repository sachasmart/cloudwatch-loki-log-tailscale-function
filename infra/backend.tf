terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~>6.0.0"
    }
  }
  backend "local" {
    path = "terraform.tfstate" # change to operator preference
  }
}
