resource "aws_acm_certificate" "cert" {
  for_each = var.domain_names

  domain_name       = each.key
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "cert_validation" {
  for_each = { for domain, zone_id in var.domain_names : domain => zone_id if zone_id != "" }

  allow_overwrite = true
  name            = tolist(aws_acm_certificate.cert[each.key].domain_validation_options)[0].resource_record_name
  records         = [tolist(aws_acm_certificate.cert[each.key].domain_validation_options)[0].resource_record_value]
  type            = tolist(aws_acm_certificate.cert[each.key].domain_validation_options)[0].resource_record_type
  zone_id         = each.value
  ttl             = 60

  depends_on = [aws_acm_certificate.cert]
}

resource "aws_acm_certificate_validation" "cert" {
  for_each = { for domain, zone_id in var.domain_names : domain => zone_id if zone_id != "" }

  certificate_arn         = aws_acm_certificate.cert[each.key].arn
  validation_record_fqdns = [aws_route53_record.cert_validation[each.key].fqdn]
}
