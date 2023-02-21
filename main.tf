# Single OIDC provider used by all roles.
resource "aws_iam_openid_connect_provider" "github" {
  # Values here from https://github.com/aws-actions/configure-aws-credentials#sample-iam-role-cloudformation-template
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["a031c46782e6e6c662c2c87c76da9aa62ccabd8e", "6938fd4d98bab03faadb97b34396831e3780aea1"]
}

# Role and policies for Serverless
resource "aws_iam_role" "github_serverless" {
  count = length(var.serverless_repositories) > 0 ? 1 : 0
  name  = "github_serverless"

  # Based on https://github.com/aws-actions/configure-aws-credentials#sample-iam-role-cloudformation-template
  assume_role_policy = templatefile("${path.module}/templates/assume_role_policy.json.tpl", { assume_role_repositories = var.serverless_repositories, oidc_provider_arn = aws_iam_openid_connect_provider.github.arn })
}

resource "aws_iam_role_policy_attachment" "github_serverless_attachment" {
  count      = length(var.serverless_policies)
  role       = aws_iam_role.github_serverless[0].name
  policy_arn = var.serverless_policies[count.index]
}

resource "aws_iam_policy" "github_serverless_deploy_policy" {
  count       = length(var.serverless_repositories) > 0 ? 1 : 0
  name        = "github_serverless_deploy_policy"
  description = "Additional permissions required to create and deploy serverless apps from Github Actions."

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
	      "iam:GetRole",
	      "iam:PassRole",
	      "iam:CreateRole",
	      "iam:DeleteRole",
	      "iam:DetachRolePolicy",
	      "iam:PutRolePolicy",
	      "iam:AttachRolePolicy",
	      "iam:DeleteRolePolicy",
	      "iam:UpdateAssumeRolePolicy",
	      "iam:ListRoleTags",
	      "iam:ListUserTags",
	      "iam:TagRole",
	      "iam:TagUser",
	      "iam:UntagRole",
	      "iam:UntagUser"
      ],
      "Resource": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/*-${var.env}-${data.aws_region.current.name}-lambdaRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "github_serverless_iam_permissions" {
  count      = length(var.serverless_policies) > 0 ? 1 : 0
  role       = aws_iam_role.github_serverless[count.index].name
  policy_arn = aws_iam_policy.github_serverless_deploy_policy[0].arn
}

resource "aws_iam_policy" "github_serverless_kms_access_policy" {
  count       = var.kms_key != "" ? 1 : 0
  name        = "github_serverless_kms_access_policy"
  description = "Additional permissions required to create and deploy serverless apps from Github Actions."

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "kms:decrypt",
      "Resource": "${data.aws_kms_key.parameter_store_key[0].arn}"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "github_serverless_kms_access_policy_attachment" {
  count      = length(var.serverless_policies) > 0 ? 1 : 0
  role       = aws_iam_role.github_serverless[count.index].name
  policy_arn = aws_iam_policy.github_serverless_kms_access_policy[0].arn
}


# Amplify resources
resource "aws_iam_role" "github_amplify" {
  count              = length(var.amplify_repositories) > 0 ? 1 : 0
  name               = "github_amplify"
  assume_role_policy = templatefile("${path.module}/templates/assume_role_policy.json.tpl", { assume_role_repositories = var.amplify_repositories, oidc_provider_arn = aws_iam_openid_connect_provider.github.arn })
}

resource "aws_iam_policy" "github_amplify_base_permissions" {
  count       = length(var.amplify_repositories) > 0 ? 1 : 0
  name        = "github_amplify_policy"
  description = "Permissions required for GitHub Actions to create Amplify deployments."

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
	      "amplify:CreateApp",
        "amplify:CreateBranch",
        "amplify:CreateDeployment",
        "amplify:DeleteApp",
        "amplify:DeleteBranch",
        "amplify:DeleteJob",
        "amplify:GetApp",
        "amplify:GetBranch",
        "amplify:GetJob",
        "amplify:StartDeployment",
        "amplify:StartJob",
        "amplify:StopJob",
        "amplify:TagResource",
        "amplify:UntagResource",
        "amplify:UpdateApp",
        "amplify:UpdateBranch"
      ],
      "Resource": ${jsonencode(formatlist("arn:aws:amplify:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:apps/%s", concat(var.amplify_applications, formatlist("%s/*", var.amplify_applications))), )}
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "github_amplify_base_permissions" {
  count      = length(var.amplify_repositories) > 0 ? 1 : 0
  role       = aws_iam_role.github_amplify[0].name
  policy_arn = aws_iam_policy.github_amplify_base_permissions[0].arn
}

resource "aws_iam_role_policy_attachment" "github_amplify_additional_attachments" {
  for_each   = length(var.amplify_repositories) > 0 ? var.amplify_policies : []
  role       = aws_iam_role.github_amplify[0].name
  policy_arn = each.value
}

# Generic GitHub repo resources
resource "aws_iam_role" "github_oidc_repository_role" {
  for_each           = var.github_oidc_repositories
  name               = each.key
  assume_role_policy = templatefile("${path.module}/templates/assume_role_policy.json.tpl", { assume_role_repositories = each.value.repositories, oidc_provider_arn = aws_iam_openid_connect_provider.github.arn })
}

resource "aws_iam_role_policy_attachment" "github_oidc_repository_policy_attachments" {
  for_each   = { for arn in local.policy_arns : arn.policy_key => arn }
  role       = aws_iam_role.github_oidc_repository_role[each.value.repo].name
  policy_arn = each.value.policy_arn
}

resource "aws_iam_policy" "github_oidc_repository_custom_policy" {
  # Create a resource for each object with one or more elements in the custom_policy list attribute.
  for_each    = { for k, v in var.github_oidc_repositories : k => v if length(v.custom_policy) > 0 }
  name        = "${each.key}-custom-policy"
  description = "Permissions required by ${each.key} that aren't a part of an existing policy."
  policy = jsonencode({
    Version   = "2012-10-17"
    Statement = each.value.custom_policy
  })
}

resource "aws_iam_role_policy_attachment" "github_oidc_repository_custom_policy_attachment" {
  for_each   = { for k, v in var.github_oidc_repositories : k => v if length(v.custom_policy) > 0 }
  role       = aws_iam_role.github_oidc_repository_role[each.key].name
  policy_arn = aws_iam_policy.github_oidc_repository_custom_policy[each.key].arn
}

resource "aws_iam_policy" "github_oidc_repository_ecr" {
  # IAM poilcy to allow permissions to the ECR repositories containing the GitHub repository's
  # Docker images.  Only create the policy for objects whose custom_ecr_repos list attribute is not empty.
  for_each = { for k, v in var.github_oidc_repositories : k => v if length(v.custom_ecr_repos) > 0 }
  name     = "${each.key}-ecr"

  policy = templatefile("${path.module}/templates/ecr_policy.tpl", { custom_ecr_repos = formatlist("arn:aws:ecr:*:${data.aws_caller_identity.current.account_id}:repository/%s", each.value.custom_ecr_repos) })
}

resource "aws_iam_role_policy_attachment" "github_oidc_repository_ecr" {
  for_each   = { for k, v in var.github_oidc_repositories : k => v if length(v.custom_ecr_repos) > 0 }
  role       = aws_iam_role.github_oidc_repository_role[each.key].name
  policy_arn = aws_iam_policy.github_oidc_repository_ecr[each.key].arn
}

resource "aws_iam_policy" "github_oidc_repository_terraform_backend" {
  # Allow all repositories permissions to the Terraform state bucket and DynamoDB lock table.
  # Assume all Terraform states for an account will use the same S3 bucket.
  for_each = var.github_oidc_repositories
  name     = "${each.key}-terraform-backend"

  policy = templatefile("${path.module}/templates/terraform_backend.tpl", { terraform_bucket = var.terraform_bucket })
}

resource "aws_iam_role_policy_attachment" "github_oidc_repository_terraform_backend" {
  for_each   = var.github_oidc_repositories
  role       = aws_iam_role.github_oidc_repository_role[each.key].name
  policy_arn = aws_iam_policy.github_oidc_repository_terraform_backend[each.key].arn
}
