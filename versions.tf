terraform {
  required_version = ">=1.4.6"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">=5.2.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = ">= 4.0.4"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.5.1"
    }
  }
}