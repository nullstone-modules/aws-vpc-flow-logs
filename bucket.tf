locals {
  create_bucket = var.existing_bucket_arn == ""
  bucket_arn    = local.create_bucket ? aws_s3_bucket.this[0].arn : var.existing_bucket_arn
  bucket_name   = local.create_bucket ? aws_s3_bucket.this[0].bucket : split(":::", var.existing_bucket_arn)[1]
}

resource "aws_s3_bucket" "this" {
  count = local.create_bucket ? 1 : 0

  bucket = local.resource_name
  tags   = merge(local.tags, { Name = local.resource_name })

  // Flow logs are audit evidence. Destroying this block should fail rather than quietly delete
  // them; empty the bucket by hand first if that is really intended.
  force_destroy = false
}

// Every object is owned by this account and ACLs are disabled. Log delivery still sends a
// `bucket-owner-full-control` ACL, which BucketOwnerEnforced accepts.
resource "aws_s3_bucket_ownership_controls" "this" {
  count = local.create_bucket ? 1 : 0

  bucket = aws_s3_bucket.this[0].id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_public_access_block" "this" {
  count = local.create_bucket ? 1 : 0

  bucket = aws_s3_bucket.this[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  count = local.create_bucket ? 1 : 0

  bucket = aws_s3_bucket.this[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = local.kms_key_arn != "" ? "aws:kms" : "AES256"
      kms_master_key_id = local.kms_key_arn != "" ? local.kms_key_arn : null
    }

    // One KMS call per bucket per short interval instead of one per object.
    bucket_key_enabled = local.kms_key_arn != "" ? true : null
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "this" {
  count = local.create_bucket ? 1 : 0

  bucket = aws_s3_bucket.this[0].id

  rule {
    id     = "expire-flow-logs"
    status = "Enabled"

    filter {}

    expiration {
      days = var.retention_days
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}
