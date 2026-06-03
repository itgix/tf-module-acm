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

variable "create_route53_validation_records" {
  type        = bool
  default     = true
  description = "When true and a Route53 zone ID is provided, create DNS validation records and wait for certificate validation. Set to false to issue certificates without managing Route53 validation in this module."
}

variable "domain_names" {
  type        = map(string)
  default     = {}
  description = "Optional additional domain name => Route53 zone ID for extra certs. Keys equal to domain_name are ignored."
}
