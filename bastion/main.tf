data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

data "aws_vpc" "main" {
  count = var.enable && var.vpc_id == null ? 1 : 0

  filter {
    name   = "tag-key"
    values = [local.vpc_tag_key]
  }
}

data "aws_subnet_ids" "subnets" {
  count  = var.enable && length(var.subnet_ids) == 0 ? 1 : 0
  vpc_id = data.aws_vpc.main[0].id

  tags = merge(local.default_subnet_tags, var.subnet_tag_filters)
}

locals {
  name = "${var.name}-${var.environment}"

  enable            = var.enable ? 1 : 0
  enable_eip        = var.enable && var.is_public && var.enable_eip ? true : false
  cloudwatch_policy = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  ssm_policy        = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"

  // merge the user supplied string user data with our user data to register the instance with an eip on boot
  user_data = local.enable_eip ? templatefile("${path.module}/user_data.conf", {
    eip                  = aws_eip.eip[0].id
    additional_user_data = var.user_data
  }) : var.user_data

  ami_id = element(concat(data.aws_ami.bastion_ami.*.id, [var.image_id]), 0)

  default_tags = {
    Name           = "bastion-${local.name}"
    Service        = var.service
    Environment    = var.environment
    Version        = var.version_tag
    Provisioner    = "Terraform"
    Expiration     = var.expiration
    AssetTag       = var.asset_tag
    Partner        = var.partner
    Project        = var.project
    Owner          = var.owner
    Classification = var.classification
    Backup         = var.backup
  }

  tags = merge(local.default_tags, var.tags)

  security_group_ids = concat(
    flatten(aws_security_group.bastion_security_group.*.id),
    var.security_groups,
  )

  vpc_tag_key = coalesce(var.vpc_tag_key_override, var.project)
  vpc_id      = element(concat(data.aws_vpc.main.*.id, [var.vpc_id]), 0)
  subnet_ids  = concat(flatten(data.aws_subnet_ids.subnets.*.ids), var.subnet_ids)

  subnet = var.is_public ? "dmz" : "app"

  default_subnet_tags = {
    (local.subnet) = "true"
  }
}

resource "aws_launch_template" "launch_template" {
  count = local.enable

  name          = "bastion-${local.name}"
  description   = "launch template for bastion images"
  image_id      = local.ami_id
  instance_type = var.instance_type

  iam_instance_profile {
    arn = aws_iam_instance_profile.instance_profile[0].arn
  }

  key_name = var.key_name

  network_interfaces {
    associate_public_ip_address = var.is_public
    security_groups             = local.security_group_ids
    delete_on_termination       = true
  }

  dynamic "block_device_mappings" {
    for_each = var.retain_volumes ? [1] : []

    content {
      device_name = "/dev/xvda"

      ebs {
        delete_on_termination = false
        volume_type           = "gp3"
        volume_size           = 8
      }
    }
  }

  user_data                            = base64encode(local.user_data)
  instance_initiated_shutdown_behavior = var.instance_initiated_shutdown_behavior

  tag_specifications {
    resource_type = "instance"

    tags = local.tags
  }

  tag_specifications {
    resource_type = "volume"

    tags = local.tags
  }

  tags = local.tags

  lifecycle {
    ignore_changes = [description]
  }
}

resource "aws_autoscaling_group" "autoscaling_group" {
  count = local.enable

  lifecycle {
    ignore_changes = [desired_capacity]
  }

  name = "bastion-${local.name}"

  desired_capacity    = 1
  max_size            = 1
  min_size            = 0
  vpc_zone_identifier = local.subnet_ids

  launch_template {
    id      = aws_launch_template.launch_template[0].id
    version = "$Latest"
  }

  tags = [for k, v in local.tags : { key = k, value = v, propagate_at_launch = true } if v != null]
}

resource "aws_autoscaling_schedule" "morning" {
  count                  = var.enable && var.spin_up != null ? 1 : 0
  scheduled_action_name  = "spin_up"
  min_size               = 0
  max_size               = 1
  desired_capacity       = 1
  recurrence             = var.spin_up
  autoscaling_group_name = aws_autoscaling_group.autoscaling_group[0].name
}

resource "aws_autoscaling_schedule" "night" {
  count                  = var.enable && var.spin_down != null ? 1 : 0
  scheduled_action_name  = "spin_down"
  min_size               = 0
  max_size               = 1
  desired_capacity       = 0
  recurrence             = var.spin_down
  autoscaling_group_name = aws_autoscaling_group.autoscaling_group[0].name
}

resource "aws_security_group" "bastion_security_group" {
  count = local.enable

  name        = "bastion-${local.name}-egress"
  description = "Allow egress"
  vpc_id      = local.vpc_id

  tags = local.tags
}

resource "aws_security_group_rule" "egress" {
  count             = local.enable
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.bastion_security_group[0].id

  cidr_blocks = [
    "0.0.0.0/0",
  ]
}

resource "aws_security_group_rule" "ingress" {
  count = local.enable

  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "-1"
  security_group_id = aws_security_group.bastion_security_group[0].id

  cidr_blocks = var.allowed_ssh_cidrs
}

data "aws_iam_policy_document" "ssh_policy" {
  count = local.enable

  statement {
    sid = "ec2InstanceConnect"

    actions = [
      "ec2-instance-connect:SendSSHPublicKey",
    ]

    resources = [
      "arn:aws:ec2:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:instance/*",
    ]

    condition {
      test     = "StringEquals"
      variable = "ec2:osuser"

      values = [
        "ec2-user",
      ]
    }
  }

  statement {
    sid = "describeInstances"

    actions = [
      "ec2:DescribeInstances",
    ]

    resources = [
      "*",
    ]
  }

  statement {
    sid = "setDesiredCapacity"

    actions   = ["autoscaling:SetDesiredCapacity"]
    resources = [aws_autoscaling_group.autoscaling_group[0].arn]
  }
}

resource "aws_iam_instance_profile" "instance_profile" {
  count = local.enable

  name = "bastion-${local.name}"
  role = aws_iam_role.instance_role[0].name
}

resource "aws_iam_role" "instance_role" {
  count = local.enable

  name = "bastion-${local.name}"
  path = "/"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
               "Service": "ec2.amazonaws.com"
            },
            "Effect": "Allow",
            "Sid": ""
        }
    ]
}
EOF

  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "cloudwatch" {
  count = local.enable

  role       = aws_iam_role.instance_role[0].name
  policy_arn = local.cloudwatch_policy
}

resource "aws_iam_role_policy_attachment" "ssm" {
  count = local.enable

  role       = aws_iam_role.instance_role[0].name
  policy_arn = local.ssm_policy
}

data "aws_iam_policy_document" "eip_associate" {
  count = var.enable && local.enable_eip ? 1 : 0

  statement {
    sid = "eipAssociate"

    actions = [
      "ec2:AssociateAddress",
    ]

    resources = [
      "*",
    ]
  }
}

resource "aws_iam_role_policy" "eip_associate_attatch" {
  count = var.enable && local.enable_eip ? 1 : 0

  name   = "ec2AssociateAddress"
  role   = aws_iam_role.instance_role[0].name
  policy = data.aws_iam_policy_document.eip_associate[0].json
}

data "aws_ami" "bastion_ami" {
  count       = var.enable && var.image_id == null ? 1 : 0
  most_recent = true

  filter {
    name   = "name"
    values = ["amazon-linux2-bastion-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["089022728777"]
}

resource "aws_eip" "eip" {
  count = var.enable && local.enable_eip ? 1 : 0

  vpc              = true
  public_ipv4_pool = "amazon"
  tags             = local.tags
}
