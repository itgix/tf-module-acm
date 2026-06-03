# tf-module-acm

Terraform module that issues **ACM certificates** for explicit domain names (no implicit wildcard on the primary or optional extras). DNS validation uses **Route 53** when you supply hosted zone IDs.

## Behaviour

- **Primary certificate** — Always created for `domain_name` (the exact string passed to `aws_acm_certificate`).
- **Optional extra certificates** — `domain_names` is a map of `domain => route53_zone_id`. Each key gets its own cert for that **exact** domain (not `*.<domain>`). Keys equal to `domain_name` are ignored.
- **Validation** — When `create_route53_validation_records` is `true` (default) and a zone ID is provided (`r53_zone_id` for the primary, or a non-empty value in `domain_names`), the module creates the DNS validation record and waits on `aws_acm_certificate_validation`. Set `create_route53_validation_records = false` to skip Route 53 records and validation entirely (certificates are still created). An empty zone ID also skips validation for that certificate.

## Inputs (summary)

| Name | Description |
|------|-------------|
| `domain_name` | Primary certificate SAN/domain (required, non-empty). |
| `r53_zone_id` | Hosted zone ID for primary DNS validation (default `""`). |
| `create_route53_validation_records` | Create Route 53 validation records and wait for ACM validation when zone IDs are set (default `true`). |
| `domain_names` | Optional map of extra domain → zone ID for additional certs (default `{}`). |

## Outputs

| Name | Description |
|------|-------------|
| `acm_certificate_arn` | Validated primary ARN when **only** the primary cert exists (`cert_count == 1`); otherwise `null`. Uses validated ARN when `r53_zone_id != ""`. |
| `acm_certificate_arns` | Map of domain name → ARN: primary under `domain_name`, plus one entry per `domain_names` key (validated ARN when zone ID is set, else bare certificate ARN). |

## Example usage

### Primary only

```hcl
module "acm" {
  source = "git::ssh://git@gitlab.itgix.com/educatedguessteam/tf-modules/tf-module-acm.git?ref=main"

  domain_name = "api.example.com"
  r53_zone_id = "Z00955992K1ILTFSNJ91B"
}
```

### Certificate only (no Route 53 validation)

Use when DNS validation is managed outside this module (e.g. another DNS provider):

```hcl
module "acm" {
  source = "git::ssh://git@gitlab.itgix.com/educatedguessteam/tf-modules/tf-module-acm.git?ref=main"

  domain_name                           = "api.example.com"
  create_route53_validation_records     = false
}
```

### Primary + additional exact-domain certs

```hcl
module "acm" {
  source = "git::ssh://git@gitlab.itgix.com/educatedguessteam/tf-modules/tf-module-acm.git?ref=main"

  domain_name = "api.example.com"
  r53_zone_id = "Z00955992K1ILTFSNJ91B"

  domain_names = {
    "other.example.com" = "" # Leave empty if you don't use route53 for this domain
    "app.example.net"   = "Zxxxxxxxxxxxxxxxxxxxx"
  }
}
```

### Calling module with `for_each` (pattern)

```hcl
module "acm" {
  for_each = var.acm_certificates

  source = "git::ssh://git@gitlab.itgix.com/educatedguessteam/tf-modules/tf-module-acm.git?ref=main"

  domain_name = each.value.domain_name
  r53_zone_id = each.value.r53_zone_id
  domain_names = try(each.value.domain_names, {})
}
```

```hcl
acm_certificates = {
  alb-cert-1 = {
    domain_name  = "tg1.itgix.eduguess.space"
    r53_zone_id  = "Z00955992K1ILTFSNJ91B"
    domain_names = {}
  }
  alb-cert-2 = {
    domain_name = "tg2.itgix.eduguess.space"
    r53_zone_id = "Z00955992K1ILTFSNJ91B"
  }
}
```

## ChangeLog

### Unreleased / recent

- Add `create_route53_validation_records` to optionally skip Route 53 DNS validation records and `aws_acm_certificate_validation`.
- Primary validation now respects empty `r53_zone_id` (previously always created a Route 53 record).
- Optional `domain_names` map for multiple certs; internal local renamed to `additional_certs`.
- Primary validation resource depends on the Route 53 validation record for safer destroy ordering.
- Outputs: `acm_certificate_arns` uses `additional_certs`; behaviour documented above.

### v1.0.0

- Initial version: ACM certificate for a domain with Route 53–backed DNS validation.
