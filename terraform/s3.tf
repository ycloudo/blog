resource "aws_s3_bucket" "content" {
  bucket = var.domain
}

resource "aws_s3_bucket_public_access_block" "content" {
  bucket                  = aws_s3_bucket.content.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# www redirect bucket
resource "aws_s3_bucket" "www_redirect" {
  bucket = "www.${var.domain}"
}

resource "aws_s3_bucket_website_configuration" "www_redirect" {
  bucket = aws_s3_bucket.www_redirect.id

  redirect_all_requests_to {
    host_name = var.domain
    protocol  = "https"
  }
}

resource "aws_s3_bucket_public_access_block" "www_redirect" {
  bucket                  = aws_s3_bucket.www_redirect.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
