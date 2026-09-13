terraform {
  required_version = ">= 1.9.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0, < 7.0"
    }
  }
}

module "frontdoor" {
  source = "../../"

  name    = "orders"
  aliases = ["orders.example.com"]

  acm_certificate_arn = "arn:aws:acm:us-east-1:123456789012:certificate/11111111-2222-3333-4444-555555555555"

  deployments = {
    blue = {
      vpc_origin_id = "E2ABCDEFGHIJKL"
      domain_name   = "orders-blue.internal.example.com"
    }
    green = {
      vpc_origin_id = "E2MNOPQRSTUVWXY"
      domain_name   = "orders-green.internal.example.com"
    }
  }

  default_deployment = "blue"

  enable_logging = true
  logging_bucket = "example-cloudfront-logs"

  tags = {
    Environment = "production"
  }
}
