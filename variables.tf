variable "domain_name" {
  type        = string
  default     = ""
  description = "Legacy: apex zone name (e.g. dev.example.com) for a single wildcard ACM cert. Issued name is *.<domain_name>. Used when domain_names is empty; combined with r53_zone_id."
}

variable "r53_zone_id" {
  type        = string
  default     = ""
  description = "Legacy: Route53 hosted zone ID for domain_name. Ignored when domain_names is non-empty."
}

variable "domain_names" {
  type        = map(string)
  default     = {}
  description = "Map of apex zone name => Route53 hosted zone ID. Each certificate is issued only as *.<apex>. When non-empty, takes precedence over domain_name and r53_zone_id. Use an empty string for a zone when DNS is not in Route53: no validation records, no aws_acm_certificate_validation (apply will not wait)."

  validation {
    condition     = length(var.domain_names) > 0 || var.domain_name != ""
    error_message = "Provide either domain_names with at least one entry, or a non-empty domain_name (legacy single certificate)."
  }
}
