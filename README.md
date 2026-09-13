# terraform-aws-cloudfront-frontdoor

[![Terraform Validation](https://github.com/pomo-studio/terraform-aws-cloudfront-frontdoor/actions/workflows/terraform.yml/badge.svg)](https://github.com/pomo-studio/terraform-aws-cloudfront-frontdoor/actions/workflows/terraform.yml)
[![Terraform Registry](https://img.shields.io/badge/terraform-registry-844FBA?logo=terraform)](https://registry.terraform.io/modules/pomo-studio/cloudfront-frontdoor/aws)

[Changelog](CHANGELOG.md)

The public front door for the Internet Ingress blueprint: a CloudFront distribution with the cache, security, and logging policy around it, pointed at one or more private VPC origins.

## When to use it

Reach for this module when you have private origins, from [`pomo-studio/cloudfront-vpc-origin/aws`](https://registry.terraform.io/modules/pomo-studio/cloudfront-vpc-origin/aws), and you want CloudFront to own the public edge: aliases, certificate, WAF, access logging, cache and origin request policy, and one behaviour per deployment.

Use a different tool when you only need the private connection (that is `cloudfront-vpc-origin`), or when you need per-request routing between deployments (that is [`pomo-studio/cloudfront-edge-router/aws`](https://registry.terraform.io/modules/pomo-studio/cloudfront-edge-router/aws)).

## Quickstart

```hcl
module "frontdoor" {
  source  = "pomo-studio/cloudfront-frontdoor/aws"
  version = "~> 0.1"

  name    = "orders"
  aliases = ["orders.example.com"]

  acm_certificate_arn = aws_acm_certificate.orders.arn

  deployments = {
    blue = {
      vpc_origin_id = module.origin_blue.id
      domain_name   = aws_lb.orders_blue.dns_name
      is_default    = true
    }
    green = {
      vpc_origin_id = module.origin_green.id
      domain_name   = aws_lb.orders_green.dns_name
      path_pattern  = "/green/*"
    }
  }

  enable_logging = true
  logging_bucket = aws_s3_bucket.logs.bucket

  tags = { Environment = "production" }
}
```

## What it creates

| Resource | Count |
|----------|-------|
| CloudFront distribution | 1 |
| Origin (VPC origin) | one per deployment |
| Default cache behaviour | 1 |
| Ordered cache behaviour | one per non-default deployment |
| Viewer certificate | 1 |
| Access log configuration | 0-1 |

## Design decisions

- **One origin per deployment.** Each colour is its own origin and its own behaviour, so the deployment lives in the path and the cache key; blue and green never share a cached object.
- **The origin domain is supplied, not discovered.** CloudFront asks for the origin DNS name alongside the VPC origin id, so each deployment passes the load balancer name it already knows.
- **VPC origins drop the `Host` header.** VPC origins reject a forwarded `Host`, so the default origin request policy is `AllViewerExceptHostHeader` rather than `AllViewer`.
- **The caller supplies the certificate and any WAF.** The module wires them in when given, rather than creating DNS or a web ACL it does not own.
- **Rollout state is not a distribution attribute.** Active colour and weight live in Parameter Store and are read at the edge by `cloudfront-edge-router`, so promoting a deployment is not a `terraform apply`.

## Examples

- [Basic](examples/basic/): a default deployment plus a second colour served on a path.

## Reference

<details>
<summary>Reference</summary>

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.0, < 7.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 5.0, < 7.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_cloudfront_distribution.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_distribution) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_acm_certificate_arn"></a> [acm\_certificate\_arn](#input\_acm\_certificate\_arn) | ARN of the ACM certificate in us-east-1 that covers the aliases. Required when aliases are set. | `string` | `null` | no |
| <a name="input_aliases"></a> [aliases](#input\_aliases) | Alternate domain names (CNAMEs) for the distribution | `list(string)` | `[]` | no |
| <a name="input_allowed_methods"></a> [allowed\_methods](#input\_allowed\_methods) | HTTP methods the distribution forwards to the origin | `list(string)` | <pre>[<br/>  "GET",<br/>  "HEAD",<br/>  "OPTIONS"<br/>]</pre> | no |
| <a name="input_cache_policy_id"></a> [cache\_policy\_id](#input\_cache\_policy\_id) | Cache policy for the behaviours. Defaults to the managed CachingOptimized policy. | `string` | `"658327ea-f89d-4fab-a63d-7e88639e58f6"` | no |
| <a name="input_default_root_object"></a> [default\_root\_object](#input\_default\_root\_object) | Object CloudFront returns for requests to the root URL | `string` | `null` | no |
| <a name="input_deployments"></a> [deployments](#input\_deployments) | Deployment colours keyed by name. Each points at a VPC origin; exactly one must set is\_default, or the map must hold a single entry. | <pre>map(object({<br/>    vpc_origin_id = string<br/>    domain_name   = string<br/>    path_pattern  = optional(string, "/*")<br/>    is_default    = optional(bool, false)<br/>  }))</pre> | n/a | yes |
| <a name="input_enable_logging"></a> [enable\_logging](#input\_enable\_logging) | Write access logs to logging\_bucket | `bool` | `true` | no |
| <a name="input_enable_waf"></a> [enable\_waf](#input\_enable\_waf) | Associate a web ACL with the distribution | `bool` | `false` | no |
| <a name="input_http_version"></a> [http\_version](#input\_http\_version) | Maximum HTTP version CloudFront serves | `string` | `"http2and3"` | no |
| <a name="input_logging_bucket"></a> [logging\_bucket](#input\_logging\_bucket) | S3 bucket for standard access logs. Required when enable\_logging is true. | `string` | `null` | no |
| <a name="input_logging_prefix"></a> [logging\_prefix](#input\_logging\_prefix) | Key prefix for access log objects | `string` | `null` | no |
| <a name="input_name"></a> [name](#input\_name) | Name of the distribution and its supporting resources | `string` | n/a | yes |
| <a name="input_origin_request_policy_id"></a> [origin\_request\_policy\_id](#input\_origin\_request\_policy\_id) | Origin request policy for the behaviours. Defaults to AllViewerExceptHostHeader, which VPC origins require. | `string` | `"b689b0a8-53d0-40ab-baf2-68738e2966ac"` | no |
| <a name="input_price_class"></a> [price\_class](#input\_price\_class) | CloudFront price class for the distribution | `string` | `"PriceClass_All"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags applied to all resources | `map(string)` | `{}` | no |
| <a name="input_wait_for_deployment"></a> [wait\_for\_deployment](#input\_wait\_for\_deployment) | Wait for the distribution to deploy before the apply completes | `bool` | `true` | no |
| <a name="input_web_acl_id"></a> [web\_acl\_id](#input\_web\_acl\_id) | ARN of the web ACL to associate when enable\_waf is true | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_arn"></a> [arn](#output\_arn) | ARN of the CloudFront distribution |
| <a name="output_distribution_id"></a> [distribution\_id](#output\_distribution\_id) | ID of the CloudFront distribution |
| <a name="output_domain_name"></a> [domain\_name](#output\_domain\_name) | CloudFront-assigned domain name |
| <a name="output_hosted_zone_id"></a> [hosted\_zone\_id](#output\_hosted\_zone\_id) | Route 53 hosted zone ID of the distribution |
| <a name="output_status"></a> [status](#output\_status) | Deployment status of the distribution |
<!-- END_TF_DOCS -->

</details>

## Support and license

Part of the [pomo-studio](https://github.com/pomo-studio) Terraform modules, run in production by [postmodern.](https://pomo.studio). Regenerate the reference with `terraform-docs` v0.20.0 (`terraform-docs .`); CI fails on drift.

See the [contribution guide](https://github.com/pomo-studio/.github/blob/main/CONTRIBUTING.md) and [security policy](https://github.com/pomo-studio/.github/blob/main/SECURITY.md).

MIT licensed. See [LICENSE](LICENSE).
