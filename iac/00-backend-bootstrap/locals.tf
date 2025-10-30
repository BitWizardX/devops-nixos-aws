locals {
  prefix         = "${var.project}-${var.environment}"
  s3_bucket_name = "${local.prefix}-opentofu-state-${data.aws_caller_identity.current.account_id}"
}
