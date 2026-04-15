output "acm_certificate_arn" {
  description = "When exactly one apex is configured: ARN of the wildcard *.<apex> certificate. Null when multiple certificates are defined."
  value = length(local.domain_names) == 1 ? one([
    for domain, zone_id in local.domain_names :
    zone_id != ""
    ? aws_acm_certificate_validation.cert[domain].certificate_arn
    : aws_acm_certificate.cf_alias[domain].arn
  ]) : null
}

output "acm_certificate_arns" {
  description = "Map of apex zone name (map key / domain_name) to ACM certificate ARN. Certificates are always *.<apex>. Issued when Route53 validation ran in Terraform; otherwise the pending certificate ARN until you validate DNS elsewhere."
  value = {
    for domain, zone_id in local.domain_names : domain => (
      zone_id != ""
      ? aws_acm_certificate_validation.cert[domain].certificate_arn
      : aws_acm_certificate.cf_alias[domain].arn
    )
  }
}
