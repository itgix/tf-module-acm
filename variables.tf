variable "domain_name" {
  type        = string
  default     = ""
  description = "Legacy: primary domain for a single ACM certificate. Used when domain_names is empty; combined with r53_zone_id."
}

variable "r53_zone_id" {
  type        = string
  default     = ""
  description = "Legacy: Route53 hosted zone ID for domain_name. Ignored when domain_names is non-empty."
}

variable "domain_names" {
  type        = map(string)
  default     = {}
  description = "Map of ACM certificate primary domain name to Route53 hosted zone ID. When non-empty, takes precedence over domain_name and r53_zone_id. Use an empty string for a zone when DNS is not in Route53: no validation records, no aws_acm_certificate_validation (apply will not wait)."

  validation {
    condition     = length(var.domain_names) > 0 || var.domain_name != ""
    error_message = "Provide either domain_names with at least one entry, or a non-empty domain_name (legacy single certificate)."
  }
}
