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
# resource "aws_alb_listener" "https_listener" {
#   load_balancer_arn = aws_alb.ecs_cluster_alb.id
#   port              = "443"
#   protocol          = "HTTPS"
#   ssl_policy        = "ELBSecurityPolicy-2016-08"
#   certificate_arn   = var.certificate_arn

#   default_action {
#     type = "fixed-response"

#     fixed_response {
#       content_type = "text/plain"
#       message_body = "Fixed response content from ${aws_alb.ecs_cluster_alb.id}"
#       status_code  = "200"
#     }
#   }
# }

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

# Attach policy to the service role
resource "aws_iam_policy_attachment" "ecs_service_role_atachment_policy" {
  name       = "ecs-service-role-${var.project_name}-policy-attachment"
  roles      = [aws_iam_role.ecs_service_role.name]
  policy_arn = aws_iam_policy.ecs_service_policy.arn
}


data "null_data_source" "asg-tags" {
  count = length(keys(var.tags))

  inputs = {
    key                 = element(keys(var.tags), count.index)
    value               = element(values(var.tags), count.index)
    propagate_at_launch = "true"
  }
}
