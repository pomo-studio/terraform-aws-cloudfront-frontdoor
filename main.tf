locals {
  declared_defaults = [for name, deployment in var.deployments : name if deployment.is_default]
  single_deployment = length(var.deployments) == 1 ? keys(var.deployments)[0] : null
  default_name      = length(local.declared_defaults) > 0 ? local.declared_defaults[0] : local.single_deployment
  ordered_names     = [for name in sort(keys(var.deployments)) : name if name != local.default_name]
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
    cache_policy_id          = var.cache_policy_id
    origin_request_policy_id = var.origin_request_policy_id
    compress                 = true
  }

  dynamic "ordered_cache_behavior" {
    for_each = local.ordered_names

    content {
      path_pattern     = var.deployments[ordered_cache_behavior.value].path_pattern
      target_origin_id = ordered_cache_behavior.value

      viewer_protocol_policy   = "redirect-to-https"
      allowed_methods          = var.allowed_methods
      cached_methods           = ["GET", "HEAD"]
      cache_policy_id          = var.cache_policy_id
      origin_request_policy_id = var.origin_request_policy_id
      compress                 = true
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
      condition     = local.default_name != null
      error_message = "Exactly one deployment must set is_default = true, or deployments must hold a single entry."
    }

    precondition {
      condition     = length(local.declared_defaults) <= 1
      error_message = "Only one deployment may set is_default = true."
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
