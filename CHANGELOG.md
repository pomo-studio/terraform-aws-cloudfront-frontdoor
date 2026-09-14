# Changelog

All notable changes to this module are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the project
adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2026-09-13

### Added

- The `cloudfront-frontdoor` distribution: one VPC origin per deployment, a
  cache policy keyed on the deployment header, CloudFront Function associations
  for the edge router, viewer certificate, optional WAF association, and
  optional access logging.
