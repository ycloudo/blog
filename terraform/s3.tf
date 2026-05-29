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

# S3 website hosting requires public access to serve the redirect response.
# This bucket contains no content — only a redirect rule to the apex domain.
resource "aws_s3_bucket_public_access_block" "www_redirect" {
  bucket                  = aws_s3_bucket.www_redirect.id
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}
