resource "aws_acm_certificate" "cf_alias" {
  domain_name       = var.domain_name
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "cert_validation" {
  allow_overwrite = true
  name            = tolist(aws_acm_certificate.cf_alias.domain_validation_options)[0].resource_record_name
  records         = [ tolist(aws_acm_certificate.cf_alias.domain_validation_options)[0].resource_record_value ]
  type            = tolist(aws_acm_certificate.cf_alias.domain_validation_options)[0].resource_record_type
  zone_id         = var.cf_domain_r53_zone
  ttl             = 60
  depends_on = [
    aws_acm_certificate.cf_alias
  ]
}

resource "aws_acm_certificate_validation" "cert" {
  certificate_arn         = aws_acm_certificate.cf_alias.arn
  validation_record_fqdns = [ aws_route53_record.cert_validation.fqdn ]
}
