resource "aws_flow_log" "this" {
  vpc_id                   = local.vpc_id
  traffic_type             = var.traffic_type
  max_aggregation_interval = var.max_aggregation_interval
  log_destination_type     = "s3"
  log_destination          = local.bucket_arn

  destination_options {
    file_format                = "parquet"
    hive_compatible_partitions = true
    per_hour_partition         = false
  }

  tags = merge(local.tags, { Name = local.resource_name })

  // Creating the flow log checks that delivery can write to the bucket. Without the bucket policy
  // in place first, creation can fail with "Access Denied for LogDestination".
  depends_on = [aws_s3_bucket_policy.this]
}
