locals {
  create_updater           = var.auto_update && var.enable ? 1 : 0
  canonical_name           = "bastion-launch-template-updater-${random_id.id.hex}"
  lambda_description       = "Updates ASG launch configuratiom template for bastion tagged ${random_id.id.hex}"
  cloudwatch_log_retention = 14

  asg_groupname      = var.enable ? aws_autoscaling_group.autoscaling_group[0].name : null
  launch_template_id = var.enable ? aws_launch_template.launch_template[0].id : null
}

resource "random_id" "id" {
  byte_length = 8
}

resource "aws_cloudwatch_log_group" "updater_logs" {
  count             = local.create_updater
  name              = "/aws/lambda/${local.canonical_name}"
  retention_in_days = local.cloudwatch_log_retention
}

resource "aws_iam_role" "lambda" {
  count = local.create_updater
  name  = local.canonical_name

  assume_role_policy  = data.aws_iam_policy_document.lambda_assumerole[0].json
  managed_policy_arns = ["arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"]

  inline_policy {
    name   = "lambda-policy"
    policy = data.aws_iam_policy_document.lambda_permissions[0].json
  }
}

data "aws_iam_policy_document" "lambda_assumerole" {
  count = local.create_updater
  statement {
    sid     = "AssumeRole"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "lambda_permissions" {
  count = local.create_updater
  statement {
    sid    = "describeimages"
    effect = "Allow"
    actions = [
      "ec2:DescribeImages"
    ]
    resources = ["*"]
  }
  statement {
    sid    = "createlaunchtemplateversion"
    effect = "Allow"
    actions = [
      "ec2:CreateLaunchTemplateVersion"
    ]
    resources = [aws_launch_template.launch_template[0].arn]
  }
}

data "archive_file" "lambda" {
  count       = local.create_updater
  type        = "zip"
  source_file = "${path.module}/main.py"
  output_path = "${path.module}/lambda.zip"
}

resource "aws_lambda_function" "updater" {
  count         = local.create_updater
  function_name = local.canonical_name
  description   = local.lambda_description
  role          = aws_iam_role.lambda[0].arn

  filename         = data.archive_file.lambda[0].output_path
  source_code_hash = filebase64sha256(data.archive_file.lambda[0].output_path)

  runtime     = "python3.8"
  handler     = "main.lambda_handler"
  timeout     = 30
  memory_size = 128

  environment {
    variables = {
      LOG_LEVEL          = "INFO",
      ASG_GROUPNAME      = local.asg_groupname
      LAUNCH_TEMPLATE_ID = local.launch_template_id
    }
  }

  depends_on = [
    aws_iam_role.lambda,
    aws_cloudwatch_log_group.updater_logs
  ]
}

resource "aws_cloudwatch_event_rule" "updater" {
  count               = local.create_updater
  name                = local.canonical_name
  schedule_expression = var.updater_schedule
}

resource "aws_cloudwatch_event_target" "updater" {
  count     = local.create_updater
  rule      = aws_cloudwatch_event_rule.updater[0].name
  target_id = random_id.id.hex
  arn       = aws_lambda_function.updater[0].arn
}

resource "aws_lambda_permission" "updater" {
  count         = local.create_updater
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.updater[0].arn
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.updater[0].arn
}
