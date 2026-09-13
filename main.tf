# The distribution and its policy are being designed against the Internet
# Ingress blueprint. This module will create:
#
#   - one aws_cloudfront_distribution whose origins are the VPC origins passed
#     in var.deployments
#   - a default cache behaviour plus one ordered behaviour per deployment
#   - managed cache and origin request policies, keyed on the deployment colour
#   - viewer certificate wiring for var.aliases and var.acm_certificate_arn
#   - optional WAF association and standard access logging
#
# Keeping the distribution behind this module lets the edge router change the
# active deployment without touching the distribution itself.
