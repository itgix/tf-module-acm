locals {
  # Legacy: only domain_name + r53_zone_id (domain_names empty). Keeps original state addresses (cf_alias, etc.).
  use_legacy_singleton = length(var.domain_names) == 0 && var.domain_name != ""

  # Map keys are apex zone names; ACM primary name is always *.<apex>.
  domain_names = length(var.domain_names) > 0 ? var.domain_names : {
    (var.domain_name) = var.r53_zone_id
  }
}

# -----------------------------------------------------------------------------
# Legacy single wildcard cert — same resource names as original module + count [0].
# -----------------------------------------------------------------------------

resource "aws_acm_certificate" "cf_alias" {
  count = local.use_legacy_singleton ? 1 : 0

  domain_name       = "*.${var.domain_name}"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "cert_validation" {
  count = local.use_legacy_singleton && var.r53_zone_id != "" ? 1 : 0

  allow_overwrite = true
  name            = tolist(aws_acm_certificate.cf_alias[0].domain_validation_options)[0].resource_record_name
  records         = [tolist(aws_acm_certificate.cf_alias[0].domain_validation_options)[0].resource_record_value]
  type            = tolist(aws_acm_certificate.cf_alias[0].domain_validation_options)[0].resource_record_type
  zone_id         = var.r53_zone_id
  ttl             = 60

  depends_on = [aws_acm_certificate.cf_alias]
}

resource "aws_acm_certificate_validation" "cert" {
  count = local.use_legacy_singleton && var.r53_zone_id != "" ? 1 : 0

  certificate_arn         = aws_acm_certificate.cf_alias[0].arn
  validation_record_fqdns = [aws_route53_record.cert_validation[0].fqdn]
}

# -----------------------------------------------------------------------------
# Multiple wildcard certs (domain_names set) — for_each; distinct addresses from legacy.
# -----------------------------------------------------------------------------

resource "aws_acm_certificate" "cert" {
  for_each = local.use_legacy_singleton ? {} : local.domain_names

  domain_name       = "*.${each.key}"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "cert_validation_for_each" {
  for_each = local.use_legacy_singleton ? {} : { for domain, zone_id in local.domain_names : domain => zone_id if zone_id != "" }

  allow_overwrite = true
  name            = tolist(aws_acm_certificate.cert[each.key].domain_validation_options)[0].resource_record_name
  records         = [tolist(aws_acm_certificate.cert[each.key].domain_validation_options)[0].resource_record_value]
  type            = tolist(aws_acm_certificate.cert[each.key].domain_validation_options)[0].resource_record_type
  zone_id         = each.value
  ttl             = 60

  depends_on = [aws_acm_certificate.cert]
}

resource "aws_acm_certificate_validation" "cert_for_each" {
  for_each = local.use_legacy_singleton ? {} : { for domain, zone_id in local.domain_names : domain => zone_id if zone_id != "" }

  certificate_arn         = aws_acm_certificate.cert[each.key].arn
  validation_record_fqdns = [aws_route53_record.cert_validation_for_each[each.key].fqdn]
}

# State migration from original module: unindexed resources -> [0]
# moved {
#   from = aws_acm_certificate.cf_alias
#   to   = aws_acm_certificate.cf_alias[0]
# }

# moved {
#   from = aws_route53_record.cert_validation
#   to   = aws_route53_record.cert_validation[0]
# }

# moved {
#   from = aws_acm_certificate_validation.cert
#   to   = aws_acm_certificate_validation.cert[0]
# }
