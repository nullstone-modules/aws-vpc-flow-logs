# VPC Flow Logs
#### nullstone/aws-vpc-flow-logs

---

## What Does This Module Do?
Turns on <a href="https://docs.aws.amazon.com/vpc/latest/userguide/flow-logs.html" target="_blank">VPC flow logs</a> for one network and delivers them to S3.

- Logs are written as **Parquet** with **Hive-compatible partitions**, so Athena or any other Hive-aware engine can query them without a crawler or a custom partition scheme.
- Records are aggregated over **600 seconds** by default, which writes fewer, larger records than the 60-second option.
- **All** traffic is recorded by default, accepted and rejected alike.

By default the module creates the bucket, with:
- Block Public Access on and ACLs disabled (`BucketOwnerEnforced`).
- SSE-S3 encryption, or SSE-KMS when a KMS key is connected.
- A bucket policy that requires TLS and lets only this account's log delivery (`delivery.logs.amazonaws.com`) write to it.
- A lifecycle rule that expires objects after `retention_days` (default 365).
- `force_destroy` off, so destroying the block fails while logs remain rather than deleting them.

---

## When Should I Use This?
When you need a record of the traffic in a network: for a security or firewall review, incident investigation, or confirming that traffic is allowed and denied where you intend.

---

## Parameters
| Name                       | Type   | Default | Description |
| -------------------------- | ------ | ------- | ----------- |
| `traffic_type`             | string | `ALL`   | Which flows to record: `ALL`, `ACCEPT` or `REJECT`. Keep `ALL` if the logs are evidence that traffic was allowed where intended; `REJECT` alone cannot show that. |
| `max_aggregation_interval` | number | `600`   | Longest time, in seconds, a flow is aggregated into one record: `60` or `600`. |
| `retention_days`           | number | `365`   | Days to keep flow log objects before S3 expires them. Only applies to a bucket this module creates. |
| `existing_bucket_arn`      | string | `""`    | ARN of an existing bucket to deliver to instead of creating one. See [Using an existing bucket](#using-an-existing-bucket). |

## Connections
| Name      | Contract            | Required | Description |
| --------- | ------------------- | -------- | ----------- |
| `network` | `network/aws/vpc`   | yes      | The network to log. Its `vpc_id` output is used. Works with `nullstone/aws-network` and `nullstone/aws-existing-network`. |
| `kms_key` | `datastore/aws/kms` | no       | Encrypts the created bucket with this customer-managed key instead of SSE-S3. See [Encryption](#encryption). |

## Outputs
| Name           | Description |
| -------------- | ----------- |
| `bucket_name`  | Name of the bucket that receives the flow logs. |
| `bucket_arn`   | ARN of the bucket that receives the flow logs. |
| `flow_log_id`  | ID of the flow log, e.g. `fl-0123456789abcdef0`. |
| `flow_log_arn` | ARN of the flow log. |
| `log_prefix`   | Key prefix the logs are written under: `AWSLogs/aws-account-id=<id>/aws-service=vpcflowlogs/aws-region=<region>/`, with `year=/month=/day=` partitions below it. |

---

## How Do I Use This?
Add a block connected to the network you want to log. A network-wide block goes under `blocks`:

```yaml
blocks:
  vpc-flow-logs:
    module: nullstone/aws-vpc-flow-logs
    connections:
      network: network0
```

To keep the logs for a different period, or record rejected traffic only:

```yaml
blocks:
  vpc-flow-logs:
    module: nullstone/aws-vpc-flow-logs
    vars:
      retention_days: 400
      traffic_type: REJECT
    connections:
      network: network0
```

Use one block per network. To log a VPC that Nullstone did not create, register it with `nullstone/aws-existing-network` first and connect to that.

---

## Cost
Flow logs are billed as vended logs, on the volume delivered.

| Destination                 | Delivery price (first 10 TB/month) |
| --------------------------- | ---------------------------------- |
| S3 (this module)            | $0.25/GB                           |
| CloudWatch Logs             | $0.50/GB, plus $0.03/GB-month stored |

Delivering to S3 costs half as much per GB as CloudWatch Logs. On top of delivery:
- **Parquet conversion** adds $0.035/GB delivered.
- **Storage** is S3 Standard. Parquet is compressed, so the stored size is well below the delivered volume; check the bucket after the first month.
- **Aggregation**: 600 seconds produces fewer records than 60 seconds for long-lived flows, so less volume is delivered.

For example, a network delivering 72 GB a month costs about $18 in delivery and $2.50 in Parquet conversion with this module, against about $36 to ingest the same logs into CloudWatch Logs, before storage. Prices are for us-east-1; check the <a href="https://aws.amazon.com/cloudwatch/pricing/" target="_blank">CloudWatch pricing page</a> (Vended Logs) for your region.

---

## Querying
With Hive-compatible partitions, an Athena table can be created over `s3://<bucket_name>/<log_prefix>` with `year`, `month` and `day` as partition columns, and `MSCK REPAIR TABLE` (or partition projection) picks up new days. See <a href="https://docs.aws.amazon.com/athena/latest/ug/vpc-flow-logs.html" target="_blank">Querying Amazon VPC flow logs</a>.

---

## Encryption
Without a `kms_key` connection, the created bucket uses SSE-S3 (AES256), which needs no key policy.

With a customer-managed key connected, the bucket uses SSE-KMS with S3 Bucket Keys. The key policy must allow `delivery.logs.amazonaws.com` to call `kms:GenerateDataKey*` (and `kms:Decrypt`), or delivery fails. The AWS-managed `aws/s3` key cannot be used: its policy is immutable and does not grant the log delivery service.

---

## Using an existing bucket
Set `existing_bucket_arn` to deliver to a bucket you already have, such as a central log-archive bucket. The module then creates only the flow log, and does not change that bucket's policy, encryption or lifecycle. `retention_days` has no effect.

The bucket's policy must allow log delivery to write under `AWSLogs/`. With Hive-compatible partitions the keys look like `AWSLogs/aws-account-id=<id>/...`, so a policy resource of `AWSLogs/<id>/*` (as in the AWS example) does not match; use `AWSLogs/*` and scope by `aws:SourceAccount` instead. See `policy.tf` in this module for a working policy.
