variable "env" {
  description = "Name of the environment being deployed to."
  type        = string
}

# TODO: Configure correct type and default values.
variable "github_oidc_repositories" {
  description = "Map of objects that specifying arbitrary number of repositories and their desired IAM permissions through a single policy doc and/or a list of existing policy ARNs.  The key for each object will be used as the role name."
  type = map(object({
    repositories           = list(string)
    policy_arns            = list(string)
    custom_ecr_repos       = optional(list(string))
    terraform_state_bucket = optional(string)
    custom_policy = optional(list(object({
      Sid      = string,
      Effect   = string,
      Action   = list(string),
      Resource = list(string)
    })))
  }))
  default = {}
}

variable "serverless_repositories" {
  description = "List of serverless repositories that are permitted to obtain AWS credentials for the github/serverless role in Github Actions."
  type        = list(string)
  default     = []
}

variable "serverless_policies" {
  description = "List of additional existing policy ARNs that should be attached to the serverless role."
  type        = list(string)
  default     = []
}

variable "amplify_repositories" {
  description = "Set of repository names (not including the owner) that should be granted access to the amplify role."
  type        = set(string)
  default     = []
}

variable "amplify_policies" {
  description = "Set of additional policy ARNs that should be attached to the amplify role."
  type        = set(string)
  default     = []
}

variable "amplify_applications" {
  description = "List of Amplify Application IDs that these repositories should be allowed to manage."
  type        = list(string)
  default     = []
}

variable "terraform_bucket" {
  description = "String of bucket which holds terraform lock and state files."
  type        = string
  default     = "sportsengine-staging-terraform-state"
}

variable "kms_key" {
  description = "Optional variable that specifies the path to key stored in AWS KMS."
  type        = string
  default     = ""
}