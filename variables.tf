variable "domain_names" {
  type        = map(string)
  description = "Map of ACM certificate primary domain name to Route53 hosted zone ID for DNS validation. Use an empty string when DNS is not in Route53: no validation records, no aws_acm_certificate_validation (apply will not wait). Use the certificate ARN output and complete validation in your DNS provider before attaching the cert to listeners."

  validation {
    condition     = length(var.domain_names) > 0
    error_message = "domain_names must contain at least one certificate entry."
  }
}
