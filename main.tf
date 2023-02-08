// airflow environment
resource "aws_mwaa_environment" "airflow" {
  name                            = "${var.division}-${var.service}-${data.aws_region.current.name}-${var.environment}"
  airflow_version                 = var.airflow_version
  dag_s3_path                     = var.dag_s3_path
  environment_class               = var.environment_class
  execution_role_arn              = length(var.execution_role_arn) > 0 ? var.execution_role_arn : aws_iam_role.airflow[0].arn
  weekly_maintenance_window_start = var.weekly_maintenance_window_start
  min_workers                     = var.min_workers
  max_workers                     = var.max_workers
  source_bucket_arn               = length(var.source_bucket_arn) > 0 ? var.source_bucket_arn : aws_s3_bucket.airflow[0].arn
  kms_key                         = length(var.kms_key) > 0 ? var.kms_key : aws_kms_key.airflow[0].arn
  webserver_access_mode           = var.webserver_access_mode

  logging_configuration {
    dag_processing_logs {
      enabled   = var.dag_processing_logs_enabled
      log_level = var.dag_processing_logs_level
    }

    scheduler_logs {
      enabled   = var.scheduler_logs_enabled
      log_level = var.scheduler_logs_level
    }

    task_logs {
      enabled   = var.task_logs_enabled
      log_level = var.task_logs_level
    }

    webserver_logs {
      enabled   = var.webserver_logs_enabled
      log_level = var.webserver_logs_level
    }

    worker_logs {
      enabled   = var.worker_logs_enabled
      log_level = var.worker_logs_level
    }
  }

  network_configuration {
    security_group_ids = length(var.security_group_ids) > 0 ? var.security_group_ids : [aws_security_group.airflow[0].id]
    subnet_ids         = length(var.subnet_ids) > 0 ? var.subnet_ids : slice(tolist(data.aws_subnet_ids.private_subnets.ids), 0, 2)
  }

  tags = local.tags
}


//airflow bucket 

resource "aws_s3_bucket" "airflow" {
  count  = length(var.source_bucket_arn) > 0 ? 0 : 1
  bucket = "${var.division}-${var.service}-${data.aws_region.current.name}-${var.environment}"

  tags = local.tags
}

resource "aws_s3_object" "dags" {
  count   = length(var.source_bucket_arn) > 0 ? 0 : 1
  bucket  = aws_s3_bucket.airflow[0].id
  key     = "dags/.keep"
  content = ""
}

resource "aws_s3_object" "requirements" {
  count   = length(var.source_bucket_arn) > 0 ? 0 : 1
  bucket  = aws_s3_bucket.airflow[0].id
  key     = "requirements/.keep"
  content = ""
}

resource "aws_s3_object" "plugins" {
  count   = length(var.source_bucket_arn) > 0 ? 0 : 1
  bucket  = aws_s3_bucket.airflow[0].id
  key     = "plugins/.keep"
  content = ""
}

resource "aws_s3_bucket_public_access_block" "airflow" {
  count  = length(var.source_bucket_arn) > 0 ? 0 : 1
  bucket = aws_s3_bucket.airflow[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "airflow" {
  count  = length(var.source_bucket_arn) > 0 ? 0 : 1
  bucket = aws_s3_bucket.airflow[0].id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "airflow" {
  count  = length(var.source_bucket_arn) > 0 ? 0 : 1
  bucket = aws_s3_bucket.airflow[0].bucket

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

//kms key
resource "aws_kms_key" "airflow" {
  count  = length(var.kms_key) > 0 ? 0 : 1
  tags   = local.tags
  policy = data.aws_iam_policy_document.kms.json
}

resource "aws_kms_alias" "airflow" {
  count         = length(var.kms_key) > 0 ? 0 : 1
  name          = "alias/airflow"
  target_key_id = aws_kms_key.airflow[0].key_id
}

//airflow security groups

resource "aws_security_group" "airflow" {
  count       = length(var.security_group_ids) > 0 ? 0 : 1
  vpc_id      = var.vpc_id
  description = "Allow traffic to the ${var.division}-${var.service}-${data.aws_region.current.name}-${var.environment} environment"

  tags = local.tags
}

//sg rules for other security groups
resource "aws_security_group_rule" "airflow_self_ingress" {
  count             = length(var.security_group_ids) > 0 ? 0 : 1
  security_group_id = aws_security_group.airflow[0].id
  description       = "Airflow self ingress rule"
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  self              = true
}

resource "aws_security_group_rule" "airflow_egress" {
  count             = length(var.security_group_ids) > 0 ? 0 : 1
  security_group_id = aws_security_group.airflow[0].id
  description       = "Airflow egress rule"
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "allow_security_group_rules" {
  for_each                 = toset(var.allowed_security_groups)
  security_group_id        = aws_security_group.airflow[0].id
  description              = "Additional security groups"
  type                     = "ingress"
  from_port                = "443"
  to_port                  = "443"
  protocol                 = "tcp"
  source_security_group_id = each.value
}

resource "aws_security_group_rule" "allowed_subnet_cidrs" {
  for_each          = toset(var.allowed_subnet_cidrs)
  security_group_id = aws_security_group.airflow[0].id
  description       = "Additional subnet CIDRs"
  type              = "ingress"
  from_port         = "443"
  to_port           = "443"
  protocol          = "tcp"

  cidr_blocks = [
    each.value,
  ]
}

resource "aws_security_group_rule" "allowed_cidr_ranges" {
  for_each          = toset(var.allowed_cidr_ranges)
  security_group_id = aws_security_group.airflow[0].id
  description       = "Additional CIDR blocks"
  type              = "ingress"
  from_port         = "443"
  to_port           = "443"
  protocol          = "tcp"

  cidr_blocks = [
    each.value,
  ]
}

// execution iam role
resource "aws_iam_role" "airflow" {
  count              = length(var.execution_role_arn) > 0 ? 0 : 1
  name               = "${var.division}-${var.service}-${data.aws_region.current.name}-${var.environment}"
  assume_role_policy = data.aws_iam_policy_document.airflow_role_assume_policy.json

  tags = local.tags
}

data "aws_iam_policy_document" "airflow_role_policy" {
  # https://docs.aws.amazon.com/mwaa/latest/userguide/mwaa-create-role.html#mwaa-create-role-how-create-role
  statement {
    effect = "Allow"
    actions = [
      "airflow:PublishMetrics"
    ]
    resources = [
      "arn:aws:airflow:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:environment/${var.division}-${var.service}-${data.aws_region.current.name}-${var.environment}"
    ]
  }

  statement {
    effect  = "Deny"
    actions = ["s3:ListAllMyBuckets"]
    resources = [
      aws_s3_bucket.airflow[0].arn,
      "${aws_s3_bucket.airflow[0].arn}/*"
    ]
  }

  # Allow Role to access our DAGs in S3
  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject*",
      "s3:GetBucket*",
      "s3:List*"
    ]
    resources = [
      aws_s3_bucket.airflow[0].arn,
      "${aws_s3_bucket.airflow[0].arn}/*"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:CreateLogGroup",
      "logs:PutLogEvents",
      "logs:GetLogEvents",
      "logs:GetLogRecord",
      "logs:GetLogGroupFields",
      "logs:GetQueryResults"
    ]
    resources = [
      "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:airflow-${var.division}-${var.service}-${data.aws_region.current.name}-${var.environment}-*"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "logs:DescribeLogGroups"
    ]
    resources = [
      "*"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "s3:GetAccountPublicAccessBlock",
      "s3:GetBucketPublicAccessBlock"
    ]
    resources = [
      "*"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "cloudwatch:PutMetricData"
    ]
    resources = [
      "*"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "sqs:ChangeMessageVisibility",
      "sqs:DeleteMessage",
      "sqs:GetQueueAttributes",
      "sqs:GetQueueUrl",
      "sqs:ReceiveMessage",
      "sqs:SendMessage"
    ]
    resources = [
      "arn:aws:sqs:${data.aws_region.current.name}:*:airflow-celery-*"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:DescribeKey",
      "kms:GenerateDataKey*",
      "kms:Encrypt"
    ]
    resources = length(var.kms_key) > 0 ? [var.kms_key] : ["arn:aws:kms:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:key/${aws_kms_key.airflow[0].key_id}"]

    condition {
      test     = "StringLike"
      variable = "kms:ViaService"
      values = [
        "sqs.${data.aws_region.current.name}.amazonaws.com",
        "s3.${data.aws_region.current.name}.amazonaws.com"
      ]
    }
  }
}

data "aws_iam_policy_document" "airflow_role_assume_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"
    principals {
      type = "Service"
      identifiers = [
        "airflow-env.amazonaws.com",
        "airflow.amazonaws.com"
      ]
    }
  }
}

data "aws_iam_policy_document" "kms" {
  statement {
    actions = [
      "kms:*"
    ]
    effect = "Allow"
    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
      ]
    }

    resources = ["*"]
  }

  statement {
    actions = [
      "kms:Encrypt*",
      "kms:Decrypt*",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:Describe*"
    ]
    effect = "Allow"
    principals {
      type = "Service"
      identifiers = [
        "logs.${data.aws_region.current.name}.amazonaws.com"
      ]
    }

    resources = ["*"]
    condition {
      test     = "ArnLike"
      variable = "kms:EncryptionContext:aws:logs:arn"
      values = [
        "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:*"
      ]
    }
  }
}

resource "aws_iam_policy" "airflow" {
  count       = length(var.execution_role_arn) > 0 ? 0 : 1
  name        = "${var.division}-${var.service}-${data.aws_region.current.name}-${var.environment}"
  description = "Policy for ${var.division}-${var.service}-${data.aws_region.current.name}-${var.environment} Airflow"
  policy      = data.aws_iam_policy_document.airflow_role_policy.json
}

resource "aws_iam_role_policy_attachment" "airflow" {
  count      = length(var.execution_role_arn) > 0 ? 0 : 1
  role       = aws_iam_role.airflow[0].name
  policy_arn = aws_iam_policy.airflow[0].arn
}
