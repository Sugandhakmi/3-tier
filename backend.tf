terraform {
  backend "s3" {
    bucket          = "bucket_name"
    key             = "terraform/terraform.tfstate"
    region          = "us-east-1"
    dynamodb_table  = "tf-state"
   }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"      
      access_key = ""
      secret_key = ""    ## we can also use arn of the role created for Terraform"
    }
  required_version = "1.2.9"
}
