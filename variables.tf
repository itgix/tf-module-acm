variable "domain_name" {
  type = string
}
variable "cf_domain_r53_zone" {
  default = ""
  description = "Route53 zone. If domain name is specified and a cert needs to be created"
}
