data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_subnet_ids" "private_subnets" {
  vpc_id = var.vpc_id
  filter {
    name   = "tag:Name"
    values = var.subnet_filter_values
  }
}
