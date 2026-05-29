terraform {
  backend "s3" {
    bucket         = "cloudo-blog-s3"
    key            = "blog/terraform.tfstate"
    region         = "ap-east-2"
    dynamodb_table = "terraform-state-lock"
    encrypt                = true
    skip_region_validation = true
  }
}
