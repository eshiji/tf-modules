### Security 

# ALB Security group
# This is the group you need to edit if you want to restrict access to your application
resource "aws_security_group" "alb_sg" {
  name_prefix = "${var.env}-${var.project_name}-alb-sg"
  description = "Controls access to the ALB"
  vpc_id      = var.vpc_id

  revoke_rules_on_delete = "true"

  ingress {
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = var.cidr_block_whitelist
  }

  ingress {
    protocol    = "tcp"
    from_port   = 443
    to_port     = 443
    cidr_blocks = var.cidr_block_whitelist
    description = "Accept traffic from all cidr blocks in cidr_block_whitelist"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(
    {
      "Name" = "${var.env}-${var.project_name}-alb-sg"
    },
    var.tags,
  )
}

# Traffic to the ECS Cluster should only come from the ALB
resource "aws_security_group" "ecs_cluster_sg" {
  name_prefix = "${var.env}-${var.project_name}"
  description = "Allow inbound access from the ALB only"
  vpc_id      = var.vpc_id

  revoke_rules_on_delete = "true"

  ingress {
    protocol        = "tcp"
    from_port       = "0"
    to_port         = "65535"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(
    {
      "Name" = "${var.env}-${var.project_name}-sg"
    },
    var.tags,
  )
}

# ALB creation
resource "aws_alb" "ecs_cluster_alb" {
  name               = "${var.env}-${var.project_name}"
  subnets            = var.public_subnets_id
  security_groups    = [aws_security_group.alb_sg.id]
  load_balancer_type = "application"

  tags = merge(
    {
      "Name" = "${var.env}-${var.project_name}-alb"
    },
    var.tags,
  )
}

# Redirect all traffic from the ALB to the target group
resource "aws_alb_listener" "http_listener" {
  load_balancer_arn = aws_alb.ecs_cluster_alb.id
  port              = "80"
  protocol          = "HTTP"

  #ssl_policy       = "ELBSecurityPolicy-2016-08"
  #certificate_arn  =

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "Fixed response content from ${aws_alb.ecs_cluster_alb.id}"
      status_code  = "200"
    }
  }
}

# Add listener rule ssl
resource "aws_alb_listener" "https_listener" {
  load_balancer_arn = aws_alb.ecs_cluster_alb.id
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = var.certificate_arn

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "Fixed response content from ${aws_alb.ecs_cluster_alb.id}"
      status_code  = "200"
    }
  }
}

# Create ecs cluster
resource "aws_ecs_cluster" "ecs-cluster" {
  name = "${var.env}-${var.project_name}"

  tags = merge(
    {
      "Name" = "${var.env}-${var.project_name}"
    },
    var.tags,
  )
}

# Associate policy document with policy 
data "aws_iam_policy_document" "ecs_service_role" {
  statement {
    actions = [
      "ec2:DescribeTags",
      "ecs:CreateCluster",
      "ecs:DeregisterContainerInstance",
      "ecs:DiscoverPollEndpoint",
      "ecs:Poll",
      "ecs:RegisterContainerInstance",
      "ecs:StartTelemetrySession",
      "ecs:UpdateContainerInstancesState",
      "ecs:Submit*",
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    sid       = "AmazonEC2ContainerServiceforEC2Role"
    effect    = "Allow"
    resources = ["*"]
  }
}

# Create iam policy for ecs_service_role
resource "aws_iam_policy" "ecs_service_policy" {
  name   = "${var.env}-${var.project_name}-ecs-service-policy"
  path   = "/"
  policy = data.aws_iam_policy_document.ecs_service_role.json
}

# Create ecs service role
resource "aws_iam_role" "ecs_service_role" {
  name                  = "${var.project_name}-${var.env}-ecs-service-role"
  force_detach_policies = "true"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "1",
      "Effect": "Allow",
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": [
          "ecs.amazonaws.com"
        ]
      }
    }
  ]
}
EOF


  tags = merge(
    {
      "Name" = "${var.env}-${var.project_name}"
    },
    var.tags,
  )
}

# Attach policy to the service role
resource "aws_iam_policy_attachment" "ecs_service_role_atachment_policy" {
  name       = "ecs-service-role-${var.project_name}-policy-attachment"
  roles      = [aws_iam_role.ecs_service_role.name]
  policy_arn = aws_iam_policy.ecs_service_policy.arn
}

# Create intance profile to be used on ec2 instance creation
resource "aws_iam_instance_profile" "ecs_instance_profile" {
  name = "${var.env}-${var.project_name}-ecs-instance-profile"
  role = aws_iam_role.ecs_service_role.name
}

# Create ec2 lauch configuration to be used by autoscaling group
resource "aws_launch_configuration" "asg_ec2_launch_configuration" {
  name_prefix                 = "${var.env}-${var.project_name}-asg-launch-config"
  image_id                    = var.ecs_instance_ami
  instance_type               = var.ec2_instance_type
  iam_instance_profile        = aws_iam_instance_profile.ecs_instance_profile.name
  security_groups             = [aws_security_group.ecs_cluster_sg.id]
  associate_public_ip_address = "True"

  root_block_device {
    volume_type = "gp2"
    volume_size = "20"
  }

  user_data = <<EOF
Content-Type: multipart/mixed; boundary="==BOUNDARY=="
MIME-Version: 1.0

--==BOUNDARY==
Content-Type: text/cloud-boothook; charset="us-ascii"
MIME-Version: 1.0

# Install nfs-utils
cloud-init-per once yum_update yum update -y
cloud-init-per once install_nfs_utils yum install -y nfs-utils

--==BOUNDARY==
Content-Type: text/x-shellscript; charset="us-ascii"
MIME-Version: 1.0

#!/bin/bash
echo ECS_CLUSTER="${aws_ecs_cluster.ecs-cluster.name}" >> /etc/ecs/ecs.config

--==BOUNDARY==--

EOF


  lifecycle {
    create_before_destroy = true
  }

  key_name = var.ec2_key_pair
}

resource "aws_key_pair" "ecs_instance_demo_key" {
  key_name   = "${var.env}-${var.project_name}-ecs-instance"
  public_key = var.ec2_pub_key

  tags = merge(
    {
      "Name" = "${var.env}-${var.project_name}"
    },
    var.tags,
  )
}

# Create appautoscaling for autoscaling group
resource "aws_autoscaling_policy" "asg_autoscaling" {
  name                   = "${var.env}-${var.project_name}-asg-autoscaling-policy"
  autoscaling_group_name = aws_autoscaling_group.asg_ec2_instances.name
  adjustment_type        = "PercentChangeInCapacity"
  depends_on             = [aws_autoscaling_group.asg_ec2_instances]
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }

    target_value = var.asg_cpu_scaling_metric_target
  }
}

data "null_data_source" "asg-tags" {
  count = length(keys(var.tags))

  inputs = {
    key                 = element(keys(var.tags), count.index)
    value               = element(values(var.tags), count.index)
    propagate_at_launch = "true"
  }
}

# Create capacity provider to scale EC2 instances if necessary
resource "aws_ecs_capacity_provider" "capacity_provider" {
  name = "${var.env}-${var.project_name}-ecs-instances"

  depends_on = [aws_autoscaling_group.asg_ec2_instances]

  auto_scaling_group_provider {
    auto_scaling_group_arn         = aws_autoscaling_group.ard
    managed_termination_protection = "ENABLED"

    managed_scaling {
      maximum_scaling_step_size = var.asg_instances_max_count
      minimum_scaling_step_size = var.asg_instances_min_count
      status                    = "ENABLED"
      target_capacity           = var.asg_instances_desired_count
    }
  }
}

# Create autoscaling group for ecs cluster ec2 instances
resource "aws_autoscaling_group" "asg_ec2_instances" {
  name                 = "${var.env}-${var.project_name}-asg-ec2-instances"
  launch_configuration = aws_launch_configuration.asg_ec2_launch_configuration.name
  vpc_zone_identifier  = var.private_subnets_id
  max_size             = var.asg_instances_max_count
  min_size             = var.asg_instances_min_count
  desired_capacity     = var.asg_instances_desired_count

  tags = [
    {
      key                 = "Name"
      value               = "${var.env}-${var.project_name}"
      propagate_at_launch = true
    },
    data.null_data_source.asg-tags.*.outputs,
  ]
}

