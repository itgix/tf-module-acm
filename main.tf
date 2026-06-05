locals {
  # Additional domain => zone (never includes primary domain_name).
  additional_certs = {
    for k, v in var.domain_names : k => v if k != var.domain_name
  }

  cert_count = 1 + length(local.additional_certs)

  primary_validate = var.create_route53_validation_records && var.r53_zone_id != ""

  additional_validate = {
    for domain, zone_id in local.additional_certs : domain => zone_id
    if var.create_route53_validation_records && zone_id != ""
  }
}

# ---------------------------
# Primary certificate (always)
# ---------------------------

resource "aws_acm_certificate" "cf_alias" {
  domain_name       = var.domain_name
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "cert_validation" {
  count = local.primary_validate ? 1 : 0

  allow_overwrite = true
  name            = tolist(aws_acm_certificate.cf_alias.domain_validation_options)[0].resource_record_name
  records         = [tolist(aws_acm_certificate.cf_alias.domain_validation_options)[0].resource_record_value]
  type            = tolist(aws_acm_certificate.cf_alias.domain_validation_options)[0].resource_record_type
  zone_id         = var.r53_zone_id
  ttl             = 60

  depends_on = [aws_acm_certificate.cf_alias]
}

resource "aws_acm_certificate_validation" "cert" {
  count = local.primary_validate ? 1 : 0

  certificate_arn         = aws_acm_certificate.cf_alias.arn
  validation_record_fqdns = [aws_route53_record.cert_validation[0].fqdn]

  depends_on = [aws_route53_record.cert_validation]
}

# -----------------------------------------------------------------------------
# Optional additional certs (per domain_names map key).
# -----------------------------------------------------------------------------

resource "aws_acm_certificate" "cert" {
  for_each = local.additional_certs

  domain_name       = each.key
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "cert_validation_for_each" {
  for_each = local.additional_validate

  allow_overwrite = true
  name            = tolist(aws_acm_certificate.cert[each.key].domain_validation_options)[0].resource_record_name
  records         = [tolist(aws_acm_certificate.cert[each.key].domain_validation_options)[0].resource_record_value]
  type            = tolist(aws_acm_certificate.cert[each.key].domain_validation_options)[0].resource_record_type
  zone_id         = each.value
  ttl             = 60

  depends_on = [aws_acm_certificate.cert]
}

resource "aws_acm_certificate_validation" "cert_for_each" {
  for_each = local.additional_validate

  certificate_arn         = aws_acm_certificate.cert[each.key].arn
  validation_record_fqdns = [aws_route53_record.cert_validation_for_each[each.key].fqdn]

  depends_on = [aws_route53_record.cert_validation_for_each]
}
