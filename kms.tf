// Optional. Without a key, objects are encrypted with SSE-S3 (AES256), which needs no key policy.
// A customer-managed key must let delivery.logs.amazonaws.com call kms:GenerateDataKey, or
// delivery fails. The AWS-managed `aws/s3` key cannot be used at all: its key policy is immutable
// and does not grant the log delivery service.
data "ns_connection" "kms_key" {
  name     = "kms_key"
  contract = "datastore/aws/kms"
  optional = true
}

locals {
  kms_key_arn = try(data.ns_connection.kms_key.outputs.kms_key_arn, "")
}
