terraform {
  backend "s3" {
    bucket       = "cloudoblog-s3"
    key          = "blog/terraform.tfstate"
    region       = "ap-northeast-1"
    use_lockfile = true
    encrypt      = true
  }
}
