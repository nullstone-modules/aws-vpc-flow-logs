output "bucket_name" {
  value       = local.bucket_name
  description = "string ||| Name of the S3 bucket that receives the flow logs"
}

output "bucket_arn" {
  value       = local.bucket_arn
  description = "string ||| ARN of the S3 bucket that receives the flow logs"
}

output "flow_log_id" {
  value       = aws_flow_log.this.id
  description = "string ||| ID of the VPC flow log (e.g. fl-0123456789abcdef0)"
}

output "flow_log_arn" {
  value       = aws_flow_log.this.arn
  description = "string ||| ARN of the VPC flow log"
}

output "log_prefix" {
  value       = "AWSLogs/aws-account-id=${local.account_id}/aws-service=vpcflowlogs/aws-region=${local.region}/"
  description = "string ||| S3 key prefix the flow logs are written under. Hive-compatible partitions (year=/month=/day=) sit below it."
}
