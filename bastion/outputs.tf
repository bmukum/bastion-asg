output "ec2_instance_connect_policy_json" {
  description = "JSON policy"
  value = element(
    concat(data.aws_iam_policy_document.ssh_policy.*.json, [""]),
    0,
  )
}

output "autoscaling_group_name" {
  description = "The name of the auto scaling group."
  value = element(
    concat(aws_autoscaling_group.autoscaling_group.*.name, [""]),
    0,
  )
}

output "autoscaling_group_arn" {
  description = "The name of the auto scaling group."
  value = element(
    concat(aws_autoscaling_group.autoscaling_group.*.arn, [""]),
    0,
  )
}

output "ec2_instance_role_name" {
  description = "Name of the iam role used on the ec2 instance profile"
  value       = element(concat(aws_iam_role.instance_role.*.name, [""]), 0)
}

output "user_data" {
  value = local.user_data
}

output "eip" {
  description = "Public IP this module assigns dynamically to the one running ec2 instance."
  value       = element(concat(aws_eip.eip.*.public_ip, [""]), 0)
}

output "security_group_id" {
  description = "Security group id for the security group placed on bastion instances"
  value = element(
    concat(aws_security_group.bastion_security_group.*.id, [""]),
    0,
  )
}

