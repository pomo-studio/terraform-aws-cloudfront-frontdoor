# Offline plan tests for terraform-aws-cloudfront-frontdoor.
#
# mock_provider keeps these running with no AWS credentials, so they gate every
# pull request. They pin the composition: one origin and behaviour per
# deployment, the default behaviour's ownership, and input validation. The live
# acceptance workflow proves the same configuration against real AWS.

mock_provider "aws" {}

variables {
  name           = "acceptance"
  enable_logging = false

  deployments = {
    blue = {
      vpc_origin_id = "E2ABCDEFGHIJKL"
      domain_name   = "blue.internal.example.com"
      is_default    = true
    }
    green = {
      vpc_origin_id = "E2MNOPQRSTUVWXY"
      domain_name   = "green.internal.example.com"
      path_pattern  = "/green/*"
    }
  }
}

run "plans_one_origin_and_behaviour_per_deployment" {
  command = apply

  assert {
    condition     = length(aws_cloudfront_distribution.this.origin) == 2
    error_message = "Each deployment should become an origin."
  }

  assert {
    condition     = aws_cloudfront_distribution.this.default_cache_behavior[0].target_origin_id == "blue"
    error_message = "The deployment marked as default should own the default behaviour."
  }

  assert {
    condition     = length(aws_cloudfront_distribution.this.ordered_cache_behavior) == 1
    error_message = "The non-default deployment should become one ordered behaviour."
  }

  assert {
    condition     = aws_cloudfront_distribution.this.ordered_cache_behavior[0].path_pattern == "/green/*"
    error_message = "The ordered behaviour should keep the deployment's path pattern."
  }
}

run "plans_a_single_deployment_without_a_default_flag" {
  command = apply

  variables {
    deployments = {
      solo = {
        vpc_origin_id = "E2ABCDEFGHIJKL"
        domain_name   = "solo.internal.example.com"
      }
    }
  }

  assert {
    condition     = aws_cloudfront_distribution.this.default_cache_behavior[0].target_origin_id == "solo"
    error_message = "A lone deployment should own the default behaviour."
  }
}

run "rejects_an_unknown_http_version" {
  command = plan

  variables {
    http_version = "http9"
  }

  expect_failures = [var.http_version]
}
