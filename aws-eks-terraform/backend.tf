terraform {
  backend "s3" {
    bucket         = "terraformstatefile090909"
    key            = "eks_ut_s3_terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }

}