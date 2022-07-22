# Bastion EC2 Terraform Module

Terraform module that spins up an autoscaling group configured to launch an ec2 instance as a bastion(jump) host. The purpose of this module is to  
allow for bastions to be rebuilt anytime and easily be updated and patched. For more detailed information on this module see the [platform blueprint](https://docs.rvapps.io/teams/platform-tools/bastions/bastions.html#how-do-i-launch-a-bastion).

By default, the module will pull the latest [RV Approved bastion AMI](https://docs.rvapps.io/teams/platform-tools/anvil/ami_releases.html) for you.  
Please note, the module pins to the latest AMI so when new AMI's are relased you will see launch template changes. This is okay and intended.

**Basic Example:**

```hcl
module "bastion_rv_ips" {
  source = "app.terraform.io/RVStandard/rvips/aws"
  version = "~> 2.0"
}

module "bastion" {
  source            = "app.terraform.io/RVStandard/bastion/aws"
  version           = "~> 3.0"

  name              = "pe-tools"
  environment       = var.workspace
  project           = var.project
  owner             = "platform-tools@redventures.com"
  allowed_ssh_cidrs = module.bastion_rv_ips.rv_ips
  spin_up           = "0 12 * * *"
  spin_down         = "0 21 * * *"
}
```

The module will add autoscaling schedule events based on the `spin_up` and `spin_down` inputs to the module. For example, the  
above inputs will launch a bastion at 8AM EST and terminate the instance at 5PM EST (timing is in UTC). If you  want to leave the bastion image running 24/7,  
omit the `spin_up` and `spin_down` inputs.

This module also creates an [Elastic IP](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/elastic-ip-addresses-eip.html).  
On launch of a new instance in the autoscaling group, the instance associates the Elastic IP with itself. This gives you and your team  
a single IP address where the bastion should be located within your `spin_up` and `spin_down` inputs.  
You shouldn't run more than one instance in the  autoscaling group this module creates.  
You can use the output `eip` of this module as an input  
to a Route53 record (i.e. bastion.someaccount-dev.redventures.io).
  * This is dependent on you using the upstream [RV Approved bastion AMI](https://platform.redventures.io/ami_pipeline/ami_releases.html).

You can ssh to the instances this module creates using [ec2 instance connect which has a few options for connecting](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/AccessingInstances.html).  
You will need IAM permissons to do so, this module has an output called `ec2_instance_connect_policy_json` which can be attached to other IAM roles, for example the developer role.

You may also need to perform actions every time a bastion instance is launched. Maybe you need to pull scripts from s3 etc. You can pass a string of user data to the module.

**User Data Example:**

```hcl
module "bastion_rv_ips" {
  source = "app.terraform.io/RVStandard/rvips/aws"
  version = "~> 2.0"
}

module "bastion" {
  source            = "app.terraform.io/RVStandard/bastion/aws"
  version           = "~> 3.0"

  name              = "pe-tools"
  environment       = var.workspace
  project           = var.project
  owner             = "platform-tools@redventures.com"
  allowed_ssh_cidrs = module.bastion_rv_ips.rv_ips
  spin_up           = "0 12 * * *"
  spin_down         = "0 21 * * *"
  user_data         = file("${path.module}/your_user_data.conf")
}
```

// your_user_data.conf
```
#/bin/bash
echo "Hello World" > /tmp/first_run
```

## Contributing

Please read [this contributing doc](https://github.com/RedVentures/terraform-abstraction/blob/main/CONTRIBUTING.md) for details around contributing to the project.

### Issues

Issues have been disabled on this project. Please create issues [here](https://github.com/RedVentures/terraform-abstraction/issues/new/choose)

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.12 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_archive"></a> [archive](#provider\_archive) | n/a |
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |
| <a name="provider_random"></a> [random](#provider\_random) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_autoscaling_group.autoscaling_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_group) | resource |
| [aws_autoscaling_schedule.morning](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_schedule) | resource |
| [aws_autoscaling_schedule.night](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_schedule) | resource |
| [aws_cloudwatch_event_rule.updater](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_rule) | resource |
| [aws_cloudwatch_event_target.updater](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_target) | resource |
| [aws_cloudwatch_log_group.updater_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_eip.eip](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eip) | resource |
| [aws_iam_instance_profile.instance_profile](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_instance_profile) | resource |
| [aws_iam_role.instance_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.eip_associate_attatch](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy_attachment.cloudwatch](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.ssm](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_lambda_function.updater](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function) | resource |
| [aws_lambda_permission.updater](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_permission) | resource |
| [aws_launch_template.launch_template](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/launch_template) | resource |
| [aws_security_group.bastion_security_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group_rule.egress](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.ingress](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [random_id.id](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/id) | resource |
| [archive_file.lambda](https://registry.terraform.io/providers/hashicorp/archive/latest/docs/data-sources/file) | data source |
| [aws_ami.bastion_ami](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) | data source |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.eip_associate](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.lambda_assumerole](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.lambda_permissions](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.ssh_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |
| [aws_subnet_ids.subnets](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnet_ids) | data source |
| [aws_vpc.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/vpc) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_allowed_ssh_cidrs"></a> [allowed\_ssh\_cidrs](#input\_allowed\_ssh\_cidrs) | CIDR ranges to allow ssh access from | `list(string)` | n/a | yes |
| <a name="input_asset_tag"></a> [asset\_tag](#input\_asset\_tag) | (Deprecated) CMDB / ServiceNow identifier | `string` | `null` | no |
| <a name="input_auto_update"></a> [auto\_update](#input\_auto\_update) | Implement periodic launch template updater lambda | `bool` | `false` | no |
| <a name="input_backup"></a> [backup](#input\_backup) | (Deprecated) Automation tag which defines backup schedule to apply | `string` | `null` | no |
| <a name="input_classification"></a> [classification](#input\_classification) | (Deprecated) Coded data sensitivity. Valid values are 'Romeo', 'Sieraa', 'India', 'Lima', 'Echo', 'Restricted', 'Sensitive', 'Internal', 'Limited External', 'External' | `string` | `null` | no |
| <a name="input_enable"></a> [enable](#input\_enable) | Whether or not to enable the resources in this module | `bool` | `true` | no |
| <a name="input_enable_eip"></a> [enable\_eip](#input\_enable\_eip) | Whether or not to enable creating and updating an elastic IP for the current running instance | `bool` | `true` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment to which the application belongs. | `string` | n/a | yes |
| <a name="input_expiration"></a> [expiration](#input\_expiration) | (Deprecated) Date resource should be removed or reviewed | `string` | `null` | no |
| <a name="input_image_id"></a> [image\_id](#input\_image\_id) | The ami-id for the image you would like to be specified in the launch template | `string` | `null` | no |
| <a name="input_instance_initiated_shutdown_behavior"></a> [instance\_initiated\_shutdown\_behavior](#input\_instance\_initiated\_shutdown\_behavior) | Shutdown behavior for the instances. Can be stop or terminate (Default stop) | `string` | `"stop"` | no |
| <a name="input_instance_type"></a> [instance\_type](#input\_instance\_type) | The ec2 instance type to add in the launch template | `string` | `"t3.micro"` | no |
| <a name="input_is_public"></a> [is\_public](#input\_is\_public) | Whether or not to build in public or private subnets | `bool` | `true` | no |
| <a name="input_key_name"></a> [key\_name](#input\_key\_name) | A key pair name to add to the launch template | `string` | `""` | no |
| <a name="input_name"></a> [name](#input\_name) | The name of your application | `string` | n/a | yes |
| <a name="input_owner"></a> [owner](#input\_owner) | (Deprecated) First level contact for the lambda. This can be email address or team alias | `string` | `null` | no |
| <a name="input_partner"></a> [partner](#input\_partner) | (Deprecated) Business Unit for which the application is deployed | `string` | `null` | no |
| <a name="input_project"></a> [project](#input\_project) | Project to which the bastion belongs. | `string` | n/a | yes |
| <a name="input_provisioner"></a> [provisioner](#input\_provisioner) | (Deprecated) Tool used to provision the resource | `string` | `"terraform://terraform-aws-bastion"` | no |
| <a name="input_retain_volumes"></a> [retain\_volumes](#input\_retain\_volumes) | If true, the EBS root volume attached to the bastion instance will be retained after instance deletion | `bool` | `false` | no |
| <a name="input_security_groups"></a> [security\_groups](#input\_security\_groups) | List of additional security groups to add to the ec2 instances | `list(string)` | `[]` | no |
| <a name="input_service"></a> [service](#input\_service) | (Deprecated) Function of the resource | `string` | `null` | no |
| <a name="input_spin_down"></a> [spin\_down](#input\_spin\_down) | A cron expression to add amn ASG Scheduled action to scale the ASG to 0 ec2 instances | `string` | `null` | no |
| <a name="input_spin_up"></a> [spin\_up](#input\_spin\_up) | A cron expression to add a ASG Scheduled action to spin up 1 ec2 instance | `string` | `null` | no |
| <a name="input_subnet_ids"></a> [subnet\_ids](#input\_subnet\_ids) | An optional list of subnet\_ids to provide. This overrides data lookups and you must also provide vpc\_id | `list(string)` | `[]` | no |
| <a name="input_subnet_tag_filters"></a> [subnet\_tag\_filters](#input\_subnet\_tag\_filters) | A map of additional tags to filter subnets on. Currently the only available option is az | `map(string)` | `{}` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Optionally specify additional tags to supported resources. Please reference the [AWS Implementation Guide](https://security.rvdocs.io/guides/aws-implementation.html#required-tags) for more details on what tags are required | `map(string)` | `{}` | no |
| <a name="input_updater_log_level"></a> [updater\_log\_level](#input\_updater\_log\_level) | Sets log level of LC template updater see https://docs.python.org/3/library/logging.html#levels | `string` | `"INFO"` | no |
| <a name="input_updater_schedule"></a> [updater\_schedule](#input\_updater\_schedule) | Cron like schedule expression for cloudwatch rule firing LC template updater lambda | `string` | `"cron(5 0 * * ? *)"` | no |
| <a name="input_user_data"></a> [user\_data](#input\_user\_data) | String supplied user data | `string` | `""` | no |
| <a name="input_version_tag"></a> [version\_tag](#input\_version\_tag) | (Deprecated) Distinguish between different versions of the resource | `string` | `null` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | An optional vpc\_id to provide. This overrides data lookups and you must also provide subnet\_ids | `string` | `null` | no |
| <a name="input_vpc_tag_key_override"></a> [vpc\_tag\_key\_override](#input\_vpc\_tag\_key\_override) | The tag-key to override standard VPC lookup, defaults to var.project | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_autoscaling_group_arn"></a> [autoscaling\_group\_arn](#output\_autoscaling\_group\_arn) | The name of the auto scaling group. |
| <a name="output_autoscaling_group_name"></a> [autoscaling\_group\_name](#output\_autoscaling\_group\_name) | The name of the auto scaling group. |
| <a name="output_ec2_instance_connect_policy_json"></a> [ec2\_instance\_connect\_policy\_json](#output\_ec2\_instance\_connect\_policy\_json) | JSON policy |
| <a name="output_ec2_instance_role_name"></a> [ec2\_instance\_role\_name](#output\_ec2\_instance\_role\_name) | Name of the iam role used on the ec2 instance profile |
| <a name="output_eip"></a> [eip](#output\_eip) | Public IP this module assigns dynamically to the one running ec2 instance. |
| <a name="output_security_group_id"></a> [security\_group\_id](#output\_security\_group\_id) | Security group id for the security group placed on bastion instances |
| <a name="output_user_data"></a> [user\_data](#output\_user\_data) | n/a |
<!-- END_TF_DOCS -->
