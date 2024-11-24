terraform {
  backend "s3" {
    bucket         = "s3-bucket-for-terraform-state-4kuh79"
    key            = "jenkins/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "jenkins-terraform-state-lock-table"
    encrypt        = true
  }
}