provider "aws" {
  region = "eu-central-1"
  alias = "eu"
}

provider "aws" {
  region = "us-east-1"
  alias  = "us"
}