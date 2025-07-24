
module "cdn" {
  source     = "terraform-aws-modules/cloudfront/aws"
  depends_on = [aws_s3_bucket.main]

  comment             = "My Awesome Cloudfront Distribution"
  enabled             = true
  is_ipv6_enabled     = true
  price_class         = "PriceClass_All"
  retain_on_delete    = false
  wait_for_deployment = false

  create_origin_access_identity = true
  origin_access_identities = {
    awesome_s3 = "My Cloudfront Can Access to S3"
  }

  origin = {

    something = {
      domain_name = aws_s3_bucket.main.bucket_regional_domain_name
      custom_origin_config = {
        http_port              = 80
        https_port             = 443
        origin_protocol_policy = "match-viewer"
        origin_ssl_protocols   = ["TLSv1", "TLSv1.1", "TLSv1.2"]
      }
    }

    awesome_s3 = {
      domain_name = aws_s3_bucket.main.bucket_regional_domain_name
      s3_origin_config = {
        origin_access_identity = local.s3_origin_id
      }
    }
  }

  default_cache_behavior = {
    target_origin_id       = local.s3_origin_id
    viewer_protocol_policy = "redirect-to-https"

    allowed_methods = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods  = ["GET", "HEAD"]
    min_ttl         = 3600
    default_ttl     = 5400
    max_ttl         = 7200
    query_string    = false
    compress        = true
  }

  default_root_object = "index.html"
  viewer_certificate = {
    cloudfront_default_certificate = true
  }

  web_acl_id = ""
  tags = var.tags
}

resource "aws_cloudfront_origin_access_identity" "origin_s3" {
  comment = "S3 Origin"
}

