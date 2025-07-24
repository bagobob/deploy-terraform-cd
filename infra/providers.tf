terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "6.4.0"
    }
  }

  backend "s3" {
    bucket         = "terraform-backend-terraformbackends3bucket-r65yjigjbsjq"
    key            = "infra/terraform.tfstate"
    region         = "eu-west-1"
    dynamodb_table = "terraform-backend-TerraformBackendDynamoDBTable-1A69VELB96QKC"
  }
}

provider "aws" {
  region = "eu-west-1"
}
