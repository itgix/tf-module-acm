output "acm_certificate_arn" {
  description = "Legacy: ARN of the single certificate when exactly one domain is configured. Null when multiple certificates are defined."
  value = length(local.domain_names) == 1 ? one([
    for domain, zone_id in local.domain_names :
    zone_id != ""
    ? aws_acm_certificate_validation.cert[domain].certificate_arn
    : aws_acm_certificate.cert[domain].arn
  ]) : null
}

output "acm_certificate_arns" {
  description = "Map of primary domain name to ACM certificate ARN. Issued when Route53 validation ran in Terraform; otherwise the pending certificate ARN until you validate DNS elsewhere."
  value = {
    for domain, zone_id in local.domain_names : domain => (
      zone_id != ""
      ? aws_acm_certificate_validation.cert[domain].certificate_arn
      : aws_acm_certificate.cert[domain].arn
    )
  }
}
