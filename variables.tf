variable "traffic_type" {
  type        = string
  default     = "ALL"
  description = "string ||| Which flows to record: ALL, ACCEPT or REJECT. Defaults to ALL, since accepted flows are the evidence that traffic was allowed where intended."

  validation {
    condition     = contains(["ALL", "ACCEPT", "REJECT"], var.traffic_type)
    error_message = "traffic_type must be one of ALL, ACCEPT or REJECT."
  }
}

variable "max_aggregation_interval" {
  type        = number
  default     = 600
  description = "number ||| Longest time, in seconds, a flow is aggregated into one record: 60 or 600. 600 writes fewer, larger records and costs less."

  validation {
    condition     = contains([60, 600], var.max_aggregation_interval)
    error_message = "max_aggregation_interval must be 60 or 600."
  }
}

variable "retention_days" {
  type        = number
  default     = 365
  description = "number ||| Days to keep flow log objects before S3 expires them. Only applies to a bucket this module creates."

  validation {
    condition     = var.retention_days >= 1
    error_message = "retention_days must be at least 1."
  }
}

variable "existing_bucket_arn" {
  type        = string
  default     = ""
  description = "string ||| ARN of an existing S3 bucket to deliver to, e.g. a central log-archive bucket. When set, no bucket is created, and that bucket's policy, encryption and lifecycle are its owner's responsibility."

  validation {
    condition     = var.existing_bucket_arn == "" || can(regex("^arn:aws[a-z-]*:s3:::[a-z0-9][a-z0-9.-]{1,61}[a-z0-9]$", var.existing_bucket_arn))
    error_message = "existing_bucket_arn must be an S3 bucket ARN (arn:aws:s3:::bucket-name), without a key prefix."
  }
}
