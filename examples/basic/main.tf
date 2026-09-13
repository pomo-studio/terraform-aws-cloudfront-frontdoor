module "frontdoor" {
  source = "../../"

  name    = "orders"
  aliases = ["orders.example.com"]

  acm_certificate_arn = "arn:aws:acm:us-east-1:123456789012:certificate/11111111-2222-3333-4444-555555555555"

  deployments = {
    blue  = { vpc_origin_id = "E2ABCDEFGHIJKL" }
    green = { vpc_origin_id = "E2MNOPQRSTUVWXY" }
  }

  enable_logging = true
  logging_bucket = "example-cloudfront-logs"

  tags = {
    Environment = "production"
  }
}
