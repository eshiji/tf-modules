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

data "template_file" "user_data" {
  template = file("${path.module}/user_data.sh")

  vars = {
    bucket_name = aws_s3_bucket.ovpn_files_bucket.id
    iam_role_name = aws_iam_role.ec2_role.name
    user = "ovpn"
  }
}

###################
# Launch template #
###################
resource "aws_launch_template" "launch_template" {
  name = "${var.project_name}-${var.env}"

  image_id = data.aws_ami.ubuntu.id

  key_name = var.launch_template_key_pair_name

  instance_initiated_shutdown_behavior = "stop"

  instance_type = var.launch_template_instance_type

  disable_api_termination = var.launch_template_termination_protection

  update_default_version = true

  # user_data = filebase64("${path.module}/user_data.sh")
  user_data = base64encode(data.template_file.user_data.rendered)

  block_device_mappings {
    device_name = var.launch_template_device_name

    ebs {
      volume_size           = var.launch_template_ebs_size
      delete_on_termination = false
    }
  }

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_instance_profile.name
  }

  network_interfaces {
    associate_public_ip_address = var.launch_template_associate_public_ip_address
    delete_on_termination       = var.launch_template_delete_eni_on_termination
    security_groups             = [aws_security_group.ec2_sg.id]
    description                 = "This ENI will be deleted on termination."
  }

  monitoring {
    enabled = var.launch_template_monitoring
  }

  tag_specifications {
    resource_type = "instance"

    tags = merge(
      {
        Name = "${var.project_name}-${var.env}"
      },
      var.tags,
    )
  }
}

# Launch Template EC2 Secutiry Group
resource "aws_security_group" "ec2_sg" {
  name        = "allow_tls"
  description = "Allow TLS inbound traffic"
  vpc_id      = var.vpc_id

  ingress {
    description = "TLS from VPC"
    from_port   = 1194
    to_port     = 1194
    protocol    = "udp"
    cidr_blocks = var.cidr_block_whitelist
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
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
      Name = "${var.project_name}"
    },
    var.tags
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

resource "aws_autoscaling_group" "asg" {
  name_prefix = "${var.project_name}-asg-${var.env}"

  vpc_zone_identifier = var.public_subnet_ids
  max_size            = var.asg_max_size
  min_size            = var.asg_min_size
  desired_capacity    = var.asg_desired_capacity

  launch_template {
    id      = aws_launch_template.launch_template.id
    version = "$Latest"
  }

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


# Instance Profile
resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "${var.project_name}-instance-profile-${var.env}"
  role = aws_iam_role.ec2_role.name
}

################
# EC2 IAM Role #
################
resource "aws_iam_role" "ec2_role" {
  name               = "${var.project_name}-instance-profile-${var.env}"
  path               = "/"
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

resource "aws_iam_policy" "s3fs_policy" {
  name        = "${var.project_name}-s3fs-policy-${var.env}"
  path        = "/"
  description = "Permissions for s3fs"

  policy = templatefile("${path.module}/s3fs.json", { bucket_name = aws_s3_bucket.ovpn_files_bucket.id })
}

#########################
# IAM Policy Attachment #
#########################
resource "aws_iam_policy_attachment" "policy_attach" {
  name       = "${var.project_name}-s3fs-attach-${var.env}"
  roles      = [aws_iam_role.ec2_role.name]
  policy_arn = aws_iam_policy.s3fs_policy.arn
}

# Create bucket for ovpn files
resource "aws_s3_bucket" "ovpn_files_bucket" {
  bucket = var.ovpn_files_bucket_name
  acl    = "private"

  versioning {
    enabled = true
  }

  tags = merge(
    {
      "Name" = "${var.env}-${var.project_name}-ovpn-files"
    },
    var.tags,
  )
}
