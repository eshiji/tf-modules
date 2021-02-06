#############################
# Get the latest Ubuntu ami #
#############################
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

###################
# Launch template #
###################
resource "aws_launch_template" "launch_template" {
  name = "${var.project_name}-${var.env}"

  block_device_mappings {
    device_name = "/dev/sda1"

    ebs {
      volume_size           = var.launch_template_ebs_size
      delete_on_termination = false
    }
  }

  iam_instance_profile {
    name = aws_iam_instance_profile.instance_profile.name
  }

  image_id = data.aws_ami.ubuntu.id

  instance_initiated_shutdown_behavior = "terminate"

  instance_type = var.instance_type

  network_interfaces {
    associate_public_ip_address = var.launch_template_associate_public_ip_address
    delete_on_termination       = var.launch_template_delete_eni_on_termination
    security_groups             = [aws_security_group.ec2_sg.id]
    description                 = "This ENI will be deleted on termination."
  }

  #   placement {
  #     availability_zone = var.availability_zone
  #   }

  tag_specifications {
    resource_type = "instance"

    tags = merge(
      {
        "Name" = "${var.project_name}-${var.env}"
      },
      var.tags,
    )
  }

  user_data = filebase64("${path.module}/user_data.sh")
}

##############################
# AutoScaling Group (EC2) SG #
##############################
resource "aws_security_group" "ec2_sg" {
  name        = "${var.project_name}-asg-sg-${var.env}"
  description = "Allow TLS inbound traffic"
  vpc_id      = var.vpc_id

  ingress {
    description     = "http"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    {
      "Name" = "${var.project_name}-ec2-${var.env}"
    },
    var.tags,
  )
}

#####################
# Autoscaling Group #
#####################
# Tag propagation at lauch for EC2
data "null_data_source" "asg_tags" {
  count = length(keys(var.tags))

  inputs = {
    key                 = element(keys(var.tags), count.index)
    value               = element(values(var.tags), count.index)
    propagate_at_launch = true
  }
}

resource "aws_autoscaling_group" "asg_ecs_instances" {
  name_prefix = "${var.project_name}-asg-ecs-instances-${var.env}"

  vpc_zone_identifier = var.public_subnet_ids
  max_size            = var.asg_max_size
  min_size            = var.asg_min_size
  desired_capacity    = var.asg_desired_capacity

  launch_template {
    id      = aws_launch_template.launch_template.id
    version = "$Latest"
  }

  target_group_arns = [aws_alb_target_group.tg.arn]

  tags = concat(
    [
      {
        key                 = "Name"
        value               = "${var.project_name}-${var.env}"
        propagate_at_launch = true
      },
    ],
    data.null_data_source.asg_tags.*.outputs,
  )
}

#############################
# Application Load Balancer #
############################# 
resource "aws_lb" "alb" {
  name               = "${var.project_name}-alb-sg-${var.env}"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = var.public_subnet_ids

  enable_deletion_protection = false

  tags = merge(
    {
      "Name" = "${var.project_name}-alb-${var.env}"
    },
    var.tags,
  )
}

####################
# ALB Target group #
####################
resource "aws_alb_target_group" "tg" {
  name        = "${var.env}-${var.project_name}"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "instance"

  tags = merge(
    {
      "Name" = "${var.project_name}-alb-tg-${var.env}"
    },
    var.tags,
  )
}

################
# ALB Listener #
################
resource "aws_alb_listener" "alb_listener" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_alb_target_group.tg.arn
    type             = "forward"
  }
}

##########
# ALB SG #
##########
resource "aws_security_group" "alb_sg" {
  name        = "${var.project_name}-alb-sg-${var.env}"
  description = "Allow TLS inbound traffic"
  vpc_id      = var.vpc_id

  ingress {
    description = "http"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.cidr_block_whitelist
  }

  ingress {
    description = "http"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.cidr_block_whitelist
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    {
      "Name" = "${var.project_name}-alb-sg-${var.env}"
    },
    var.tags,
  )
}

################
# EC2 IAM Role #
################
resource "aws_iam_role" "ec2_role" {
  name               = "${var.project_name}-instance-profile-${var.env}"
  path               = "/system/"
  assume_role_policy = data.aws_iam_policy_document.instance_assume_role_policy.json
}

##############
# IAM policy #
##############
data "aws_iam_policy_document" "instance_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_policy" "ec2_policy" {
  name        = "${var.project_name}-ec2-policy-${var.env}"
  path        = "/"
  description = "Permissions for EC2 actions."

  policy = file("${path.module}/ec2_policy.json")
}

resource "aws_iam_policy" "ssm_policy" {
  name        = "${var.project_name}-ssm-policy-${var.env}"
  path        = "/"
  description = "Permissions for ssm actions(sessions manager)"

  policy = file("${path.module}/ssm_policy.json")
}

resource "aws_iam_policy" "systems_manager_policy" {
  name        = "${var.project_name}-systems-manager-policy-${var.env}"
  path        = "/"
  description = "Permissions for ssm actions(sessions manager)"

  policy = file("${path.module}/systems_manager_policy.json")
}

#########################
# IAM Policy Attachment #
#########################
resource "aws_iam_policy_attachment" "policy_attach" {
  name       = "${var.project_name}-ec2-policy-attach-${var.env}"
  roles      = [aws_iam_role.ec2_role.name]
  policy_arn = aws_iam_policy.ec2_policy.arn
}

resource "aws_iam_policy_attachment" "ssm_policy_attach" {
  name       = "${var.project_name}-ssm-policy-attach-${var.env}"
  roles      = [aws_iam_role.ec2_role.name]
  policy_arn = aws_iam_policy.ssm_policy.arn
}

resource "aws_iam_policy_attachment" "systems_manager_policy_attach" {
  name       = "${var.project_name}-systems-manager-policy-attach-${var.env}"
  roles      = [aws_iam_role.ec2_role.name]
  policy_arn = aws_iam_policy.systems_manager_policy.arn
}

resource "aws_iam_instance_profile" "instance_profile" {
  name = "${var.project_name}-instance-profile-${var.env}"
  role = aws_iam_role.ec2_role.name
}