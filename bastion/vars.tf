variable "name" {
  type        = string
  description = "The name of your application"
}

variable "environment" {
  type        = string
  description = "Environment to which the application belongs."
}

variable "project" {
  type        = string
  description = "Project to which the bastion belongs."
}

variable "allowed_ssh_cidrs" {
  type        = list(string)
  description = "CIDR ranges to allow ssh access from"
}

variable "key_name" {
  type        = string
  default     = ""
  description = "A key pair name to add to the launch template"
}

variable "image_id" {
  description = "The ami-id for the image you would like to be specified in the launch template"
  default     = null
  type        = string
}

variable "enable" {
  type        = bool
  description = "Whether or not to enable the resources in this module"
  default     = true
}

variable "is_public" {
  type        = bool
  description = "Whether or not to build in public or private subnets"
  default     = true
}

variable "security_groups" {
  type        = list(string)
  default     = []
  description = "List of additional security groups to add to the ec2 instances"
}

variable "instance_type" {
  type        = string
  default     = "t3.micro"
  description = "The ec2 instance type to add in the launch template"
}

variable "spin_up" {
  type        = string
  default     = null
  description = "A cron expression to add a ASG Scheduled action to spin up 1 ec2 instance"
}

variable "spin_down" {
  type        = string
  default     = null
  description = "A cron expression to add amn ASG Scheduled action to scale the ASG to 0 ec2 instances"
}

variable "user_data" {
  type        = string
  default     = ""
  description = "String supplied user data"
}

variable "enable_eip" {
  type        = bool
  default     = true
  description = "Whether or not to enable creating and updating an elastic IP for the current running instance"
}

variable "instance_initiated_shutdown_behavior" {
  type        = string
  default     = "stop"
  description = "Shutdown behavior for the instances. Can be stop or terminate (Default stop)"
}

variable "vpc_tag_key_override" {
  type        = string
  description = "The tag-key to override standard VPC lookup, defaults to var.project"
  default     = null
}

variable "subnet_tag_filters" {
  type        = map(string)
  description = "A map of additional tags to filter subnets on. Currently the only available option is az"
  default     = {}
}

variable "vpc_id" {
  type        = string
  description = "An optional vpc_id to provide. This overrides data lookups and you must also provide subnet_ids"
  default     = null
}

variable "subnet_ids" {
  type        = list(string)
  description = "An optional list of subnet_ids to provide. This overrides data lookups and you must also provide vpc_id"
  default     = []
}

variable "tags" {
  type        = map(string)
  description = "Optionally specify additional tags to supported resources. Please reference the [AWS Implementation Guide](https://security.rvdocs.io/guides/aws-implementation.html#required-tags) for more details on what tags are required"
  default     = {}
}

variable "retain_volumes" {
  type        = bool
  description = "If true, the EBS root volume attached to the bastion instance will be retained after instance deletion"
  default     = false
}

/*
* Begin CNN Tag Variables
*/

variable "service" {
  type        = string
  description = "(Deprecated) Function of the resource"
  default     = null
}

variable "version_tag" {
  type        = string
  description = "(Deprecated) Distinguish between different versions of the resource"
  default     = null
}

variable "provisioner" {
  type        = string
  description = "(Deprecated) Tool used to provision the resource"
  default     = "terraform://terraform-aws-bastion"
}

variable "expiration" {
  type        = string
  description = "(Deprecated) Date resource should be removed or reviewed"
  default     = null
}

variable "asset_tag" {
  type        = string
  description = "(Deprecated) CMDB / ServiceNow identifier"
  default     = null
}

variable "partner" {
  type        = string
  description = "(Deprecated) Business Unit for which the application is deployed"
  default     = null
}

variable "owner" {
  type        = string
  description = "(Deprecated) First level contact for the lambda. This can be email address or team alias"
  default     = null
}

variable "classification" {
  type        = string
  description = "(Deprecated) Coded data sensitivity. Valid values are 'Romeo', 'Sieraa', 'India', 'Lima', 'Echo', 'Restricted', 'Sensitive', 'Internal', 'Limited External', 'External'"
  default     = null
}

variable "backup" {
  type        = string
  description = "(Deprecated) Automation tag which defines backup schedule to apply"
  default     = null
}

/*
* End CNN Tag Variables
*/

variable "auto_update" {
  type        = bool
  description = "Implement periodic launch template updater lambda"
  default     = false
}

variable "updater_schedule" {
  type        = string
  description = "Cron like schedule expression for cloudwatch rule firing LC template updater lambda"
  default     = "cron(5 0 * * ? *)"
}

variable "updater_log_level" {
  type        = string
  description = "Sets log level of LC template updater see https://docs.python.org/3/library/logging.html#levels"
  default     = "INFO"
}
