terraform {
  backend "s3" {
    bucket         = "prasad-ops-tfstate-bucket"
    key            = "platform/dev/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-lock-table"
  }
}