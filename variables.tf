variable "name" {
  description = "Name of the distribution and its supporting resources"
  type        = string
}

variable "deployments" {
  description = "Deployment colours keyed by name. Each maps to a VPC origin and the behaviour it serves."
  type = map(object({
    vpc_origin_id = string
    path_pattern  = optional(string, "/*")
  }))
  default = {}
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

variable "tags" {
  description = "Tags applied to all resources"
  type        = map(string)
  default     = {}
}
