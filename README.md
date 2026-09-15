# terraform-aws-cloudfront-frontdoor

[![Terraform Validation](https://github.com/pomo-studio/terraform-aws-cloudfront-frontdoor/actions/workflows/terraform.yml/badge.svg)](https://github.com/pomo-studio/terraform-aws-cloudfront-frontdoor/actions/workflows/terraform.yml)
[![Terraform Registry](https://img.shields.io/badge/terraform-registry-844FBA?logo=terraform)](https://registry.terraform.io/modules/pomo-studio/cloudfront-frontdoor/aws)

[Changelog](CHANGELOG.md)

The public front door for the Internet Ingress blueprint: a CloudFront distribution with the cache, security, and logging policy around it, pointed at one or more private VPC origins.

## When to use it

Reach for this module when you have private origins, from [`pomo-studio/cloudfront-vpc-origin/aws`](https://registry.terraform.io/modules/pomo-studio/cloudfront-vpc-origin/aws), and you want CloudFront to own the public edge: aliases, certificate, WAF, access logging, cache and origin request policy, one origin per deployment, and the function associations that let the edge router switch between them.

Use a different tool when you only need the private connection (that is `cloudfront-vpc-origin`), or when you need the per-request selection logic itself (that is [`pomo-studio/cloudfront-edge-router/aws`](https://registry.terraform.io/modules/pomo-studio/cloudfront-edge-router/aws), which this module pairs with).

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
    }
    green = {
      vpc_origin_id = module.origin_green.id
      domain_name   = aws_lb.orders_green.dns_name
    }
  }

  default_deployment = "blue"
  deployment_header  = "x-postmodern-deployment"

  function_associations = module.edge_router.function_associations

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
| Deployment-aware cache policy | 0-1 |
| Viewer certificate | 1 |
| Access log configuration | 0-1 |

## Design decisions

- **One origin per deployment.** Each colour is its own origin. A CloudFront Function selects between them per request, so the switch is a configuration change rather than an apply.
- **The cache key carries the deployment.** Selecting an origin does not change the cache key, so when `deployment_header` is set the module creates a cache policy that keys on the header the edge router stamps. Without it, blue and green can serve each other's cached objects.
- **CloudFront Functions, not Lambda@Edge.** VPC origins do not support Lambda@Edge origin request or response triggers, so origin selection runs in a CloudFront Function (JavaScript runtime 2.0, `selectRequestOriginById`).
- **The origin domain is supplied, not discovered.** CloudFront asks for the origin DNS name alongside the VPC origin id, so each deployment passes the load balancer name it already knows.
- **VPC origins drop the `Host` header.** VPC origins reject a forwarded `Host`, so the default origin request policy is `AllViewerExceptHostHeader` rather than `AllViewer`.
- **The caller supplies the certificate and any WAF.** The module wires them in when given, rather than creating DNS or a web ACL it does not own.
- **Rollout state is not a distribution attribute.** Active colour and weight live in Parameter Store and reach the edge through the router, so promoting a deployment is not a `terraform apply`.

## Examples

- [Basic](examples/basic/): two private origins behind one distribution.

## Reference

<details>
<summary>Reference</summary>

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.9.0 |
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
| [aws_cloudfront_cache_policy.deployment](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_cache_policy) | resource |
| [aws_cloudfront_distribution.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_distribution) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_acm_certificate_arn"></a> [acm\_certificate\_arn](#input\_acm\_certificate\_arn) | ARN of the ACM certificate in us-east-1 that covers the aliases. Required when aliases are set. | `string` | `null` | no |
| <a name="input_aliases"></a> [aliases](#input\_aliases) | Alternate domain names (CNAMEs) for the distribution | `list(string)` | `[]` | no |
| <a name="input_allowed_methods"></a> [allowed\_methods](#input\_allowed\_methods) | HTTP methods the distribution forwards to the origin | `list(string)` | <pre>[<br/>  "GET",<br/>  "HEAD",<br/>  "OPTIONS"<br/>]</pre> | no |
| <a name="input_cache_policy_id"></a> [cache\_policy\_id](#input\_cache\_policy\_id) | Cache policy for the behaviours. Defaults to the managed CachingOptimized policy. | `string` | `"658327ea-f89d-4fab-a63d-7e88639e58f6"` | no |
| <a name="input_default_deployment"></a> [default\_deployment](#input\_default\_deployment) | Deployment the distribution targets when the edge router does not override it. Defaults to the first deployment in sort order. | `string` | `null` | no |
| <a name="input_default_root_object"></a> [default\_root\_object](#input\_default\_root\_object) | Object CloudFront returns for requests to the root URL | `string` | `null` | no |
| <a name="input_deployment_header"></a> [deployment\_header](#input\_deployment\_header) | Request header the edge router sets to mark the chosen deployment. When set, the distribution creates a cache policy that keys on it so deployments do not share cached objects. | `string` | `null` | no |
| <a name="input_deployments"></a> [deployments](#input\_deployments) | Deployments keyed by name. Each points at a VPC origin. One deployment is the default target; the edge router can override it per request. | <pre>map(object({<br/>    vpc_origin_id = string<br/>    domain_name   = string<br/>  }))</pre> | n/a | yes |
| <a name="input_enable_logging"></a> [enable\_logging](#input\_enable\_logging) | Write access logs to logging\_bucket | `bool` | `true` | no |
| <a name="input_enable_waf"></a> [enable\_waf](#input\_enable\_waf) | Associate a web ACL with the distribution | `bool` | `false` | no |
| <a name="input_function_associations"></a> [function\_associations](#input\_function\_associations) | CloudFront Function associations for the default cache behaviour, such as the edge router on viewer-request and viewer-response. | <pre>list(object({<br/>    event_type   = string<br/>    function_arn = string<br/>  }))</pre> | `[]` | no |
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

Part of [postmodern.tf](https://pomo.dev), the open-source AWS infrastructure
collection created by [André Pitanga](https://pomo.studio). Regenerate the reference with `terraform-docs` v0.20.0 (`terraform-docs .`); CI fails on drift.

See the [contribution guide](https://github.com/pomo-studio/.github/blob/main/CONTRIBUTING.md) and [security policy](https://github.com/pomo-studio/.github/blob/main/SECURITY.md).

MIT licensed. See [LICENSE](LICENSE).
