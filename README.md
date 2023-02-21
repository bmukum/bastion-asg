# GitHub OIDC
Terraform module to deploy the necessary AWS resources to create IAM roles that are able to authenticate GitHub repositories.

The amplify and serverless repositories were originally created as their own resources, prior to the generic `github_oidc_repositories` variable was created to allow looping over a map containing an arbitrary number of repository objects including their desired policies.  These should be combined after vetting the new all-inclusive variable is working as expected across environments.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.3 |

## Providers

| Name | Version |
|------|---------|
| aws | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_iam_openid_connect_provider.github](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_openid_connect_provider) | resource |
| [aws_iam_policy.github_amplify_base_permissions](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.github_oidc_repository_custom_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.github_oidc_repository_ecr](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.github_oidc_repository_terraform_backend](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.github_serverless_deploy_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.github_serverless_kms_access_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.github_amplify](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.github_oidc_repository_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.github_serverless](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.github_amplify_additional_attachments](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.github_amplify_base_permissions](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.github_oidc_repository_custom_policy_attachment](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.github_oidc_repository_ecr](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.github_oidc_repository_policy_attachments](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.github_oidc_repository_terraform_backend](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.github_serverless_attachment](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.github_serverless_iam_permissions](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.github_serverless_kms_access_policy_attachment](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_kms_key.parameter_store_key](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/kms_key) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| amplify_applications | List of Amplify Application IDs that these repositories should be allowed to manage. | `list(string)` | `[]` | no |
| amplify_policies | Set of additional policy ARNs that should be attached to the amplify role. | `set(string)` | `[]` | no |
| amplify_repositories | Set of repository names (not including the owner) that should be granted access to the amplify role. | `set(string)` | `[]` | no |
| env | Name of the environment being deployed to. | `string` | n/a | yes |
| github_oidc_repositories | Map of objects that specifying arbitrary number of repositories and their desired IAM permissions through a single policy doc and/or a list of existing policy ARNs.  The key for each object will be used as the role name. | ```map(object({ repositories = list(string) policy_arns = list(string) custom_ecr_repos = optional(list(string)) terraform_state_bucket = optional(string) custom_policy = optional(list(object({ Sid = string, Effect = string, Action = list(string), Resource = list(string) }))) }))``` | `{}` | no |
| kms_key | Optional variable that specifies the path to key stored in AWS KMS. | `string` | `""` | no |
| serverless_policies | List of additional existing policy ARNs that should be attached to the serverless role. | `list(string)` | `[]` | no |
| serverless_repositories | List of serverless repositories that are permitted to obtain AWS credentials for the github/serverless role in Github Actions. | `list(string)` | `[]` | no |
| terraform_bucket | String of bucket which holds terraform lock and state files. | `string` | `"sportsengine-staging-terraform-state"` | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->

## Generic Repositories
The `github_oidc_repositories` variable is a map of objects that allows the calling module to pass in an arbitrary number of repositories and their desired IAM permissions through a mix of pre-defined policy templates based on the specified ECR repos and Terraform state file name, a custom policy attribute, and/or a list of existing policy ARNs to attach.  The key for each object will be used as the role name, *it is strongly prefferred to configure the role name as `github_<repository-name>`*.  The format for the object is
```hcl
github_oidc_repositories = {
    <role-name> = {
      repositories     = [] # list of GitHub repositories, not including organization/owner
      policy_arns      = [] # list of existing IAM policy ARNs to attach to the newly created role
      custom_ecr_repos = [] # list of ECR repo names that this role should have full control over
      custom_policy    = [] # list of custom IAM policy statements in HCL
    }
  }
```

**Note** - the `policy_arns` local value is used to flatten all of the `policy_arns` attributes so that they can  be used in a `for_each` loop within a single resource.  This flattening creates the `policy_key` attribute that is a combination of the repository's name and the list index of the specific policy ARN.  This could result in attachments being deleted and recreated when removing items from a repository's `policy_arns` attribute.  This was deemed to be acceptable since attachments are only logical resources and should not result in any AWS resources being recreated.

## Example Usage
```hcl
module "github_oidc" {
  source               = "git@github.com:sportngin/tflib-iam.git//github_oidc?ref=v0.7.0"
  env                  = local.environment

  github_oidc_repositories = {
    github_se-backstage = {
      repositories   = ["se-backstage"]
      policy_arns    = []
      custom_ecr_repos = ["se-backstage"]
      custom_policy  = []
    },
    github_fintech-ccpa-consumer = {
      repositories = ["fintech-ccpa-consumer"]
      policy_arns  = ["arn:aws:iam::aws:policy/EC2InstanceProfileForImageBuilderECRContainerBuilds"]
      custom_ecr_repos = ["fintech-ccpa-consumer"]
      custom_policy   = []
    }
    github_se-sales-channels-ui = {
      repositories = ["se-sales-channels-ui"]
      policy_arns  = []
      custom_ecr_repos = []
      custom_policy   = [
        {
          Sid: "AllowS3ListBucket",
          Effect: "Allow",
          Action: "s3:ListBucket",
          Resource: "arn:aws:s3:::se-sales-channels-staging"
        },
        {
          Sid: "AllowS3Sync",
          Effect: "Allow",
          Action: [
            "s3:DeleteObject",
            "s3:GetBucketLocation",
            "s3:GetObject",
            "s3:ListBucket",
            "s3:PutObject"
          ],
          Resource: "arn:aws:s3:::se-sales-channels-staging/*"
        },
        {
          Sid: "AllowInvalidateCloudFrontCache",
          Effect: "Allow",
          Action: "cloudfront:CreateInvalidation",
          Resource: [
            "arn:aws:cloudfront::${data.aws_caller_identity.current.account_id}:distribution/E1LYALD2UTG2JJ"
          ]
        },
        {
          Sid: "AllowAmplifyAccess",
          Effect: "Allow",
          Action: [
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
          Resource: [
            "arn:aws:amplify:us-east-1:108064780585:apps/d215bbwookz2ts",
            "arn:aws:amplify:us-east-1:108064780585:apps/d215bbwookz2ts/*"
          ]
        }
      ]
    }
  }
}
```