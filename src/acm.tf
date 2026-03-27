# --------------------------------------------------------------
# ACM Certificate
# --------------------------------------------------------------

resource "aws_acm_certificate" "cert" {
  count = var.domain_enabled ? 1 : 0

  domain_name               = var.domain
  subject_alternative_names = ["www.${var.domain}"]
  validation_method         = "DNS"

  tags = local.project_tags

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate_validation" "cert" {
  count = var.domain_enabled ? 1 : 0

  certificate_arn         = aws_acm_certificate.cert[0].arn
  validation_record_fqdns = [for record in aws_route53_record.acm_validation : record.fqdn]

  timeouts {
    create = "15m"
  }
}
