variable "domain_name" {
  type        = string
  description = "Primary ACM certificate domain_name (exact string for aws_acm_certificate, e.g. *.dev.example.com). Always required."

  validation {
    condition     = var.domain_name != ""
    error_message = "domain_name must be non-empty."
  }
}

variable "r53_zone_id" {
  type        = string
  default     = ""
  description = "Route53 hosted zone ID for DNS validation of the primary certificate."
}

variable "domain_names" {
  type        = map(string)
  default     = {}
  description = "Optional additional apex zone name => Route53 zone ID for extra certs issued as *.<apex>. Keys equal to domain_name are ignored."
}
