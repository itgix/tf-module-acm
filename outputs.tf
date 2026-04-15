output "acm_certificate_arn" {
  description = "When a single apex is configured: ARN of the wildcard *.<apex> cert. Null when multiple certs use domain_names."
  value = local.use_legacy_singleton ? (
    var.r53_zone_id != ""
    ? one(aws_acm_certificate_validation.cert[*].certificate_arn)
    : one(aws_acm_certificate.cf_alias[*].arn)
    ) : (
    length(var.domain_names) == 1 ? one([
      for domain, zone_id in var.domain_names :
      zone_id != ""
      ? aws_acm_certificate_validation.cert_for_each[domain].certificate_arn
      : aws_acm_certificate.cert[domain].arn
    ]) : null
  )
}

output "acm_certificate_arns" {
  description = "Map of apex zone name to ACM certificate ARN. Certificates are always *.<apex>."
  value = local.use_legacy_singleton ? {
    (var.domain_name) = (
      var.r53_zone_id != ""
      ? one(aws_acm_certificate_validation.cert[*].certificate_arn)
      : one(aws_acm_certificate.cf_alias[*].arn)
    )
    } : {
    for domain, zone_id in local.domain_names : domain => (
      zone_id != ""
      ? aws_acm_certificate_validation.cert_for_each[domain].certificate_arn
      : aws_acm_certificate.cert[domain].arn
    )
  }
}
