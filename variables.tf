variable "name" {
  description = "Name of the distribution and its supporting resources"
  type        = string
}

variable "deployments" {
  description = "Deployment colours keyed by name. Each points at a VPC origin; exactly one must set is_default, or the map must hold a single entry."
  type = map(object({
    vpc_origin_id = string
    domain_name   = string
    path_pattern  = optional(string, "/*")
    is_default    = optional(bool, false)
  }))
}

variable "aliases" {
  description = "Alternate domain names (CNAMEs) for the distribution"
  type        = list(string)
  default     = []
}

variable "acm_certificate_arn" {
  description = "ARN of the ACM certificate in us-east-1 that covers the aliases. Required when aliases are set."
  type        = string
  default     = null
}

variable "default_root_object" {
  description = "Object CloudFront returns for requests to the root URL"
  type        = string
  default     = null
}

variable "cache_policy_id" {
  description = "Cache policy for the behaviours. Defaults to the managed CachingOptimized policy."
  type        = string
  default     = "658327ea-f89d-4fab-a63d-7e88639e58f6"
}

variable "origin_request_policy_id" {
  description = "Origin request policy for the behaviours. Defaults to AllViewerExceptHostHeader, which VPC origins require."
  type        = string
  default     = "b689b0a8-53d0-40ab-baf2-68738e2966ac"
}

variable "allowed_methods" {
  description = "HTTP methods the distribution forwards to the origin"
  type        = list(string)
  default     = ["GET", "HEAD", "OPTIONS"]
}

variable "http_version" {
  description = "Maximum HTTP version CloudFront serves"
  type        = string
  default     = "http2and3"

  validation {
    condition     = contains(["http1.1", "http2", "http2and3", "http3"], var.http_version)
    error_message = "http_version must be one of: http1.1, http2, http2and3, http3."
  }
}

variable "price_class" {
  description = "CloudFront price class for the distribution"
  type        = string
  default     = "PriceClass_All"

  validation {
    condition     = contains(["PriceClass_100", "PriceClass_200", "PriceClass_All"], var.price_class)
    error_message = "price_class must be PriceClass_100, PriceClass_200, or PriceClass_All."
  }
}

variable "enable_waf" {
  description = "Associate a web ACL with the distribution"
  type        = bool
  default     = false
}

variable "web_acl_id" {
  description = "ARN of the web ACL to associate when enable_waf is true"
  type        = string
  default     = null
}

variable "enable_logging" {
  description = "Write access logs to logging_bucket"
  type        = bool
  default     = true
}

variable "logging_bucket" {
  description = "S3 bucket for standard access logs. Required when enable_logging is true."
  type        = string
  default     = null
}

variable "logging_prefix" {
  description = "Key prefix for access log objects"
  type        = string
  default     = null
}

variable "wait_for_deployment" {
  description = "Wait for the distribution to deploy before the apply completes"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags applied to all resources"
  type        = map(string)
  default     = {}
}
