# The key of the map is the cloudwatch log group, the value is the filter syntax expression.
# All matching log entries will be forwarded to a Lambda function, that forwards the entries to
# a shared bucket in the telia-common-logs-prod account.

provider "aws" {
  region = "eu-west-1"
}

locals {
  subscriptions = {
    "test" = ""
  }
}

resource "aws_s3_bucket" "artifact_bucket" {
  bucket = "splunk-forwarder-artifact-bucket"

  tags = {
    Name        = "splunk-forwarder-artifact-bucket"
    Environment = "Dev"
  }
}

resource "aws_s3_bucket" "log_bucket" {
  bucket = "splunk-forwarder-log-bucket"

  tags = {
    Name        = "splunk-forwarder-log-bucket"
    Environment = "Dev"
  }
}

resource "aws_s3_bucket_object" "object" {
  bucket = aws_s3_bucket.artifact_bucket.bucket
  key    = "myspecialkey"
  source = "./cloudwatch-logs-remote-bucket-1.6.zip"

  # The filemd5() function is available in Terraform 0.11.12 and later
  # For Terraform 0.11.11 and earlier, use the md5() function and the file() function:
  # etag = "${md5(file("path/to/file"))}"
  etag = filemd5("./cloudwatch-logs-remote-bucket-1.6.zip")
}

resource "aws_cloudwatch_log_group" "test" {
  name = "test"

  tags = {
    Environment = "Dev"
  }
}

module "cloudwatch_splunk_lambda_subscription" {
  source           = "../.."
  name_prefix      = "sample_log_forwarder"
  log_group_names  = keys(local.subscriptions)
  filter_patterns  = values(local.subscriptions)
  lambda_s3_bucket = aws_s3_bucket.artifact_bucket.bucket
  s3_key           = aws_s3_bucket_object.object.key
  log_bucket_name  = aws_s3_bucket.log_bucket.bucket
}
