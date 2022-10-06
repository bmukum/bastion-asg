data "aws_iam_policy_document" "developer_custom_trust_policy" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = [data.aws_ssm_parameter.developer_role_arn.value]
    }
  }
}

data "aws_iam_policy_document" "developer_custom_inline_policy" {
  statement {
    actions = [
      "lambda:GetFunction*",
      "lambda:ListFunctions*",
      "lambda:Update*",
      "lambda:Publish*",
      "appsync:*",
      "ssm:Get*"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role" "developer_custom_role" {
  name               = "developer-custom-role"
  assume_role_policy = data.aws_iam_policy_document.developer_custom_trust_policy.json

  inline_policy {
    name   = "developer-custom-inline-policy"
    policy = data.aws_iam_policy_document.developer_custom_inline_policy.json
  }
}
