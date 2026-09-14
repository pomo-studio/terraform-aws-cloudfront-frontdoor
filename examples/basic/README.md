# Frontdoor basics

Front two VPC origins with one CloudFront distribution and an alias.

## What it creates

- An `aws_cloudfront_distribution` for `orders.example.com` with a blue and a green origin.
- Each origin uses a `vpc_origin_config` and the matching `domain_name`.
- `blue` is the default deployment.
- Access logging to the given bucket.

## Before you start

- Provider `hashicorp/aws` with credentials for the target account.
- Uses a local source, `../../`.
- The ACM certificate in `us-east-1` and the logging bucket must already exist. The certificate ARN, VPC origin IDs, and domain names here are placeholders. Replace them with real values.

## Run it

```bash
terraform init
terraform plan
terraform apply
```

## Clean up

```bash
terraform destroy
```
