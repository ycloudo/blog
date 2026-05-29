resource "aws_acm_certificate" "blog" {
  provider          = aws.us_east_1
  domain_name       = var.domain
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

# Waits for the certificate to reach ISSUED status before CloudFront is created.
# Add the CNAME records below in Cloudflare first, then run terraform apply.
resource "aws_acm_certificate_validation" "blog" {
  provider        = aws.us_east_1
  certificate_arn = aws_acm_certificate.blog.arn
}

output "acm_validation_records" {
  description = "Add these CNAME records in Cloudflare to validate the ACM certificate"
  value = {
    for dvo in aws_acm_certificate.blog.domain_validation_options : dvo.domain_name => {
      name  = dvo.resource_record_name
      type  = dvo.resource_record_type
      value = dvo.resource_record_value
    }
  }
}
