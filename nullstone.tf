terraform {
  required_providers {
    ns = {
      source  = "nullstone-io/ns"
      version = "~> 0.13.0"
    }
    aws = {
      source = "hashicorp/aws"
      // 6.0 for data.aws_region.region (name is deprecated)
      version = ">= 6.0"
    }
  }
}

data "ns_workspace" "this" {}

// Generate a random suffix to ensure uniqueness of resources
resource "random_string" "resource_suffix" {
  length  = 5
  lower   = true
  upper   = false
  numeric = false
  special = false
}

locals {
  tags          = data.ns_workspace.this.aws_tags
  block_name    = data.ns_workspace.this.block_name
  resource_name = "${data.ns_workspace.this.block_ref}-${random_string.resource_suffix.result}"
}
