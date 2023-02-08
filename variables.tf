# Require inputs
variable "application" {
  description = "The application or service the mwaa environment is used by."
  type        = string
}

variable "service" {
  description = "The service the mwaa environment is used by."
  type        = string
}

variable "name" {
  description = "Name of the mwaa environment."
  type        = string
}

variable "business_vertical" {
  description = "The business vertical the resource belongs to."
  type        = string
}

variable "division" {
  description = "Name of the division the resources belong to."
  type        = string
}


variable "environment" {
  description = "Name of the environment being deployed to."
  type        = string
}

variable "vpc_id" {
  description = "The VPC the environment will live in."
  type        = string
}

variable "subnet_filter_values" {
  description = "List of private subnet tag names to identify subnets in which the environment would be created. Two subnets are required"
  type        = list(string)
  default     = [""]
}

#Optional Inputs
variable "airflow_version" {
  description = "The airflow version of the environment"
  type        = string
  default     = "2.4.3"
}

variable "allowed_security_groups" {
  description = "A list of additional security groups to associate with environment"
  type        = list(string)
  default     = []
}

variable "kms_key" {
  description = "KMS key ARN to use for encryption."
  type        = string
  default     = ""
}

variable "allowed_subnet_cidrs" {
  description = "A list of additional subnet CIDRs to associate with environment."
  type        = list(string)
  default     = []
}

variable "allowed_cidr_ranges" {
  description = "A list of additional cidr blocks to associate with environment."
  type        = list(string)
  default     = []
}

variable "webserver_access_mode" {
  description = "Specifies whether the webserver should be accessible over the internet or via your specified CIDRs"
  default     = "PRIVATE_ONLY"
}

variable "dag_s3_path" {
  description = "The relative path to the DAG folder on the Amazon S3 storage bucket."
  type        = string
  default     = "dags/"
}

variable "requirements_s3_path" {
  description = "The relative path to the DAG folder on the Amazon S3 storage bucket."
  type        = string
  default     = "requirements/"
}

variable "plugins_s3_path" {
  description = "The relative path to the DAG folder on the Amazon S3 storage bucket."
  type        = string
  default     = "plugins/"
}

variable "environment_class" {
  description = "The instance type for the cluster's nodes."
  type        = string
  default     = "mw1.small"
  validation {
    condition     = contains(["mw1.small", "mw1.medium", "mw1.large"], var.environment_class)
    error_message = "Environment class must be one of 'mw1.small', 'mw1.medium', or 'mw1.large'."
  }
}

variable "weekly_maintenance_window_start" {
  description = "The start date for the weekly maintenance window."
  type        = string
  default     = "MON:00:30"
}

variable "min_workers" {
  description = "The minimum number of workers that you want to run in the environment."
  type        = number
  default     = 1
}

variable "max_workers" {
  description = "The maximum number of workers that you want to run in the environment."
  type        = number
  default     = 2
}

variable "source_bucket_arn" {
  description = "The Amazon Resource Name (ARN) of the Amazon S3 storage bucket."
  type        = string
  default     = ""
}

variable "security_group_ids" {
  description = "Security groups IDs for the environment. At least one of the security group needs to allow MWAA resources to talk to each other, otherwise MWAA cannot be provisioned." # Required to support existing, manually create deployments.
  type        = list(string)
  default     = []
}

variable "execution_role_arn" {
  description = "IAM execution role for the airflow environment" # Required to support existing, manually create deployments.
  type        = string
  default     = ""
}

variable "subnet_ids" {
  description = "Minimum of 2 subnets to deploy the environment into"
  type        = list(string)
  default     = []
}

variable "additional_tags" {
  description = "Map of tags that should be assigned to the instance.  By default the application, business_vertical, environment, managed_by, and Name values will be assigned."
  type        = map(any)
  default     = {}
}

variable "dag_processing_logs_enabled" {
  type    = bool
  default = true
}
variable "dag_processing_logs_level" {
  type        = string
  description = "One of: DEBUG, INFO, WARNING, ERROR, CRITICAL"
  default     = "WARNING"
}
variable "scheduler_logs_enabled" {
  type    = bool
  default = true
}
variable "scheduler_logs_level" {
  type        = string
  description = "One of: DEBUG, INFO, WARNING, ERROR, CRITICAL"
  default     = "WARNING"
}
variable "task_logs_enabled" {
  type    = bool
  default = true
}
variable "task_logs_level" {
  type        = string
  description = "One of: DEBUG, INFO, WARNING, ERROR, CRITICAL"
  default     = "INFO"
}
variable "webserver_logs_enabled" {
  type    = bool
  default = true
}
variable "webserver_logs_level" {
  type        = string
  description = "One of: DEBUG, INFO, WARNING, ERROR, CRITICAL"
  default     = "WARNING"
}
variable "worker_logs_enabled" {
  type    = bool
  default = true
}
variable "worker_logs_level" {
  type        = string
  description = "One of: DEBUG, INFO, WARNING, ERROR, CRITICAL"
  default     = "WARNING"
}


