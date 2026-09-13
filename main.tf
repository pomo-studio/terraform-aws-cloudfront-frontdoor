locals {
  deployment_names = sort(keys(var.deployments))
  default_name = (
    var.default_deployment != null
    ? var.default_deployment
    : (length(local.deployment_names) > 0 ? local.deployment_names[0] : null)
  )
}

resource "aws_cloudfront_cache_policy" "deployment" {
  count = var.deployment_header != null ? 1 : 0

  name        = "${var.name}-deployment"
  min_ttl     = 0
  default_ttl = 86400
  max_ttl     = 31536000

  parameters_in_cache_key_and_forwarded_to_origin {
    cookies_config {
      cookie_behavior = "none"
    }

    headers_config {
      header_behavior = "whitelist"

      headers {
        items = [var.deployment_header]
      }
    }

    query_strings_config {
      query_string_behavior = "none"
    }

    enable_accept_encoding_brotli = true
    enable_accept_encoding_gzip   = true
  }
}

resource "aws_cloudfront_distribution" "this" {
  enabled             = true
  is_ipv6_enabled     = true
  comment             = var.name
  aliases             = var.aliases
  default_root_object = var.default_root_object
  http_version        = var.http_version
  price_class         = var.price_class
  web_acl_id          = var.enable_waf ? var.web_acl_id : null
  wait_for_deployment = var.wait_for_deployment

  dynamic "origin" {
    for_each = var.deployments

    content {
      origin_id   = origin.key
      domain_name = origin.value.domain_name

      vpc_origin_config {
        vpc_origin_id = origin.value.vpc_origin_id
      }
    }
  }

  default_cache_behavior {
    target_origin_id = local.default_name

    viewer_protocol_policy   = "redirect-to-https"
    allowed_methods          = var.allowed_methods
    cached_methods           = ["GET", "HEAD"]
    cache_policy_id          = var.deployment_header != null ? aws_cloudfront_cache_policy.deployment[0].id : var.cache_policy_id
    origin_request_policy_id = var.origin_request_policy_id
    compress                 = true

    dynamic "function_association" {
      for_each = var.function_associations

      content {
        event_type   = function_association.value.event_type
        function_arn = function_association.value.function_arn
      }
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = length(var.aliases) == 0
    acm_certificate_arn            = length(var.aliases) > 0 ? var.acm_certificate_arn : null
    ssl_support_method             = length(var.aliases) > 0 ? "sni-only" : null
    minimum_protocol_version       = length(var.aliases) > 0 ? "TLSv1.2_2021" : null
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  dynamic "logging_config" {
    for_each = var.enable_logging && var.logging_bucket != null ? [1] : []

    content {
      bucket          = var.logging_bucket
      include_cookies = false
      prefix          = var.logging_prefix
    }
  }

  tags = var.tags

  lifecycle {
    precondition {
      condition     = length(var.deployments) > 0
      error_message = "At least one deployment is required."
    }

    precondition {
      condition     = local.default_name != null && contains(keys(var.deployments), local.default_name)
      error_message = "default_deployment must name a deployment, or be left null with a single deployment."
    }

    precondition {
      condition     = length(var.aliases) == 0 || var.acm_certificate_arn != null
      error_message = "acm_certificate_arn is required when aliases are set."
    }

    precondition {
      condition     = !var.enable_waf || var.web_acl_id != null
      error_message = "web_acl_id is required when enable_waf is true."
    }

    precondition {
      condition     = !var.enable_logging || var.logging_bucket != null
      error_message = "logging_bucket is required when enable_logging is true."
    }
  }
}
