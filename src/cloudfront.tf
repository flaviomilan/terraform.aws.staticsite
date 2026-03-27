# --------------------------------------------------------------
# CloudFront Distribution
# --------------------------------------------------------------

resource "aws_cloudfront_distribution" "s3_distribution" {
  count = var.domain_enabled ? 1 : 0

  origin {
    domain_name              = aws_s3_bucket.s3_bucket[0].bucket_regional_domain_name
    origin_id                = local.s3_origin_id
    origin_access_control_id = aws_cloudfront_origin_access_control.cloudfront_s3_oac[0].id
  }

  enabled             = true
  is_ipv6_enabled     = true
  http_version        = "http3"
  comment             = "CloudFront distribution for ${var.domain}"
  default_root_object = "index.html"
  web_acl_id          = var.enable_waf ? aws_wafv2_web_acl.waf[0].arn : null

  aliases = [var.domain, "www.${var.domain}"]

  # SPA support: return index.html for 403/404 errors
  custom_error_response {
    error_caching_min_ttl = 10
    error_code            = 404
    response_code         = 200
    response_page_path    = "/index.html"
  }

  custom_error_response {
    error_caching_min_ttl = 10
    error_code            = 403
    response_code         = 200
    response_page_path    = "/index.html"
  }

  default_cache_behavior {
    allowed_methods            = ["GET", "HEAD", "OPTIONS"]
    cached_methods             = ["GET", "HEAD", "OPTIONS"]
    target_origin_id           = local.s3_origin_id
    response_headers_policy_id = aws_cloudfront_response_headers_policy.security_headers[0].id
    compress                   = true

    forwarded_values {
      query_string = false
      headers      = ["Origin"]

      cookies {
        forward = "none"
      }
    }

    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.rewrite_index.arn
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
      locations        = []
    }
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate.cert[0].arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = var.minimum_tls_version
  }

  tags = local.project_tags

  depends_on = [aws_acm_certificate_validation.cert]
}

# --------------------------------------------------------------
# Origin Access Control (OAC)
# --------------------------------------------------------------

resource "aws_cloudfront_origin_access_control" "cloudfront_s3_oac" {
  count = var.domain_enabled ? 1 : 0

  name                              = "oac-${var.domain}"
  description                       = "Origin Access Control for ${var.domain} S3 bucket"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# --------------------------------------------------------------
# CloudFront Function (SPA Rewrite)
# --------------------------------------------------------------

resource "aws_cloudfront_function" "rewrite_index" {
  name    = replace("rewrite-index-${var.domain}", ".", "-")
  runtime = "cloudfront-js-2.0"
  comment = "Rewrite extensionless URIs to index.html for SPA routing"
  publish = true
  code    = file("${path.module}/function/function.js")
}

# --------------------------------------------------------------
# Security Headers Policy
# --------------------------------------------------------------

resource "aws_cloudfront_response_headers_policy" "security_headers" {
  count = var.domain_enabled ? 1 : 0
  name  = replace("security-headers-${var.domain}", ".", "-")

  security_headers_config {
    strict_transport_security {
      access_control_max_age_sec = 31536000
      include_subdomains         = true
      preload                    = true
      override                   = true
    }

    xss_protection {
      protection = true
      mode_block = true
      override   = true
    }

    frame_options {
      frame_option = "SAMEORIGIN"
      override     = true
    }

    content_type_options {
      override = true
    }

    referrer_policy {
      referrer_policy = "strict-origin-when-cross-origin"
      override        = true
    }

    content_security_policy {
      content_security_policy = var.csp_policy
      override                = true
    }
  }

  custom_headers_config {
    items {
      header   = "Permissions-Policy"
      value    = "geolocation=(), microphone=(), camera=(), payment=(), usb=()"
      override = true
    }

    items {
      header   = "X-Permitted-Cross-Domain-Policies"
      value    = "none"
      override = true
    }
  }
}

# --------------------------------------------------------------
# CloudFront Real-Time Monitoring
# --------------------------------------------------------------

resource "aws_cloudfront_monitoring_subscription" "monitoring" {
  count = var.domain_enabled && var.enable_monitoring ? 1 : 0

  distribution_id = aws_cloudfront_distribution.s3_distribution[0].id

  monitoring_subscription {
    realtime_metrics_subscription_config {
      realtime_metrics_subscription_status = "Enabled"
    }
  }
}
