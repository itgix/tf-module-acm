output "acm_certificate_arn" {
  description = "ARN when only the primary certificate exists (no domain_names extras). Null if multiple certs."
  value = local.cert_count == 1 ? (
    var.r53_zone_id != ""
    ? aws_acm_certificate_validation.cert.certificate_arn
    : aws_acm_certificate.cf_alias.arn
  ) : null
}

output "acm_certificate_arns" {
  description = "Map of domain key to certificate ARN. Primary uses domain_name; extras from domain_names."
  value = merge(
    {
      (var.domain_name) = (
        var.r53_zone_id != ""
        ? aws_acm_certificate_validation.cert.certificate_arn
        : aws_acm_certificate.cf_alias.arn
      )
    },
    {
      for domain, zone_id in local.additional_certs : domain => (
        zone_id != ""
        ? aws_acm_certificate_validation.cert_for_each[domain].certificate_arn
        : aws_acm_certificate.cert[domain].arn
      )
    },
  )
}
