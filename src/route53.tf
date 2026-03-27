# --------------------------------------------------------------
# Route53 Hosted Zone
# --------------------------------------------------------------

resource "aws_route53_zone" "public_zone" {
  name          = var.domain
  comment       = "Public hosted zone for ${var.domain}"
  force_destroy = var.force_destroy_zone

  tags = local.project_tags
}

# --------------------------------------------------------------
# ACM DNS Validation Records
# --------------------------------------------------------------

resource "aws_route53_record" "acm_validation" {
  for_each = var.domain_enabled ? {
    for dvo in aws_acm_certificate.cert[0].domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  } : {}

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = aws_route53_zone.public_zone.zone_id
}

# --------------------------------------------------------------
# DNS A Record (IPv4) → CloudFront
# --------------------------------------------------------------

resource "aws_route53_record" "record_a" {
  count = var.domain_enabled ? 1 : 0

  zone_id = aws_route53_zone.public_zone.id
  name    = var.domain
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.s3_distribution[0].domain_name
    zone_id                = aws_cloudfront_distribution.s3_distribution[0].hosted_zone_id
    evaluate_target_health = false
  }
}

# --------------------------------------------------------------
# DNS AAAA Record (IPv6) → CloudFront
# --------------------------------------------------------------

resource "aws_route53_record" "record_aaaa" {
  count = var.domain_enabled ? 1 : 0

  zone_id = aws_route53_zone.public_zone.id
  name    = var.domain
  type    = "AAAA"

  alias {
    name                   = aws_cloudfront_distribution.s3_distribution[0].domain_name
    zone_id                = aws_cloudfront_distribution.s3_distribution[0].hosted_zone_id
    evaluate_target_health = false
  }
}

# --------------------------------------------------------------
# DNS A Record for www → CloudFront
# --------------------------------------------------------------

resource "aws_route53_record" "www_a" {
  count = var.domain_enabled ? 1 : 0

  zone_id = aws_route53_zone.public_zone.id
  name    = "www.${var.domain}"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.s3_distribution[0].domain_name
    zone_id                = aws_cloudfront_distribution.s3_distribution[0].hosted_zone_id
    evaluate_target_health = false
  }
}

# --------------------------------------------------------------
# DNS AAAA Record for www → CloudFront
# --------------------------------------------------------------

resource "aws_route53_record" "www_aaaa" {
  count = var.domain_enabled ? 1 : 0

  zone_id = aws_route53_zone.public_zone.id
  name    = "www.${var.domain}"
  type    = "AAAA"

  alias {
    name                   = aws_cloudfront_distribution.s3_distribution[0].domain_name
    zone_id                = aws_cloudfront_distribution.s3_distribution[0].hosted_zone_id
    evaluate_target_health = false
  }
}
