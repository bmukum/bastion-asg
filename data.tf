data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_kms_key" "parameter_store_key" {
  count  = var.kms_key != "" ? 1 : 0
  key_id = var.kms_key
}
