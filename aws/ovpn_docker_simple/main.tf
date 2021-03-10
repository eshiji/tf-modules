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

# Read user data
data "template_file" "user_data" {
  template = file("${path.module}/user_data.sh")

  vars = {
    bucket_name   = aws_s3_bucket.ovpn_files_bucket.id
    iam_role_name = aws_iam_role.ec2_role.name
    user          = var.ovpn_user
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
    cidr_blocks = var.cidr_block_udp_whitelist
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.cidr_block_ssh_whitelist
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

# EIP
resource "aws_eip" "instance_eip" {
  vpc             = true
  instance        = aws_instance.ovpn_instance.id
  security_groups = [aws_aws_security_group.ec2_sg.id]

  tags = merge(
    {
      "Name" = "${var.env}-${var.project_name}-eip"
    },
    var.tags,
  )
}

# OVPN instance

resource "aws_instance" "ovpn_instance" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  user_data              = base64encode(data.template_file.user_data.rendered)
  iam_instance_profile   = aws_iam_instance_profile.ec2_instance_profile.name
  delete_on_termination  = false
  subnet_id              = var.public_subnet_id
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]

  tags = merge(
    {
      "Name" = "${var.env}-${var.project_name}-instance"
    },
    var.tags,
  )
}

# Route53
resource "aws_route53_record" "vpn" {
  zone_id = var.zone_id
  name    = "${var.project_name}.${var.domain_name}"
  type    = "A"
  ttl     = "60"
  records = [aws_eip.instance_eip.public_ip]
}