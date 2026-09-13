# Offline plan tests for terraform-aws-cloudfront-frontdoor.
#
# mock_provider keeps these running with no AWS credentials, so they gate every
# pull request. They pin the composition: one origin per deployment, one default
# behaviour, the CloudFront Function associations that route between them, and
# the cache policy that keeps their responses apart. The live acceptance
# workflow proves the same configuration on AWS.

mock_provider "aws" {}

variables {
  name               = "acceptance"
  enable_logging     = false
  default_deployment = "blue"

  deployments = {
    blue = {
      vpc_origin_id = "E2ABCDEFGHIJKL"
      domain_name   = "blue.internal.example.com"
    }
    green = {
      vpc_origin_id = "E2MNOPQRSTUVWXY"
      domain_name   = "green.internal.example.com"
    }
  }
}

run "plans_one_origin_per_deployment" {
  command = apply

  assert {
    condition     = length(aws_cloudfront_distribution.this.origin) == 2
    error_message = "Each deployment should become an origin."
  }

  assert {
    condition     = aws_cloudfront_distribution.this.default_cache_behavior[0].target_origin_id == "blue"
    error_message = "The default behaviour should target the default deployment."
  }

  assert {
    condition     = length(aws_cloudfront_distribution.this.ordered_cache_behavior) == 0
    error_message = "Edge origin selection needs no ordered behaviours."
  }
}

run "wires_the_edge_router_functions" {
  command = apply

  variables {
    function_associations = [
      {
        event_type   = "viewer-request"
        function_arn = "arn:aws:cloudfront::123456789012:function/acceptance-router"
      },
      {
        event_type   = "viewer-response"
        function_arn = "arn:aws:cloudfront::123456789012:function/acceptance-router"
      },
    ]
  }

  assert {
    condition     = length(aws_cloudfront_distribution.this.default_cache_behavior[0].function_association) == 2
    error_message = "Both edge router functions should be attached to the default behaviour."
  }
}

run "keys_the_cache_on_the_deployment_header" {
  command = apply

  variables {
    deployment_header = "x-postmodern-deployment"
  }

  assert {
    condition     = aws_cloudfront_distribution.this.default_cache_behavior[0].cache_policy_id == aws_cloudfront_cache_policy.deployment[0].id
    error_message = "The distribution should use the deployment-aware cache policy when a header is set."
  }
}

run "defaults_to_the_first_deployment_when_unset" {
  command = apply

  variables {
    default_deployment = null
  }

  assert {
    condition     = aws_cloudfront_distribution.this.default_cache_behavior[0].target_origin_id == "blue"
    error_message = "Without a default, the first deployment in sort order should be the target."
  }
}

run "rejects_an_unknown_http_version" {
  command = plan

  variables {
    http_version = "http9"
  }

  expect_failures = [var.http_version]
}
