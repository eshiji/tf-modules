# Create iam policy for ecs_service_role
resource "aws_iam_policy" "ecs_service_policy" {
  name   = "${var.env}-${var.project_name}-ecs-service-policy"
  path   = "/"
  policy = data.aws_iam_policy_document.ecs_service_role_policy.json
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
          "ecs-tasks.amazonaws.com"
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

# Associate policy document with policy 
data "aws_iam_policy_document" "ecs_service_role_policy" {
  statement {
    actions = [
      "ec2:AttachNetworkInterface",
      "ec2:CreateNetworkInterface",
      "ec2:CreateNetworkInterfacePermission",
      "ec2:DeleteNetworkInterface",
      "ec2:DeleteNetworkInterfacePermission",
      "ec2:Describe*",
      "ec2:DetachNetworkInterface",
      "elasticloadbalancing:DeregisterInstancesFromLoadBalancer",
      "elasticloadbalancing:DeregisterTargets",
      "elasticloadbalancing:Describe*",
      "elasticloadbalancing:RegisterInstancesWithLoadBalancer",
      "elasticloadbalancing:RegisterTargets",
      "route53:ChangeResourceRecordSets",
      "route53:CreateHealthCheck",
      "route53:DeleteHealthCheck",
      "route53:Get*",
      "route53:List*",
      "route53:UpdateHealthCheck",
      "servicediscovery:DeregisterInstance",
      "servicediscovery:Get*",
      "servicediscovery:List*",
      "servicediscovery:RegisterInstance",
      "servicediscovery:UpdateInstanceCustomHealthStatus",
      "ecr:*",
      "cloudwatch:*",
      "logs:*",
      "iam:*",
      "autoscaling:Describe*",
    ]

    resources = ["*"]
  }

  statement {
    sid = "AutoScalingManagement"

    actions = [
        "autoscaling:DeletePolicy",
        "autoscaling:PutScalingPolicy",
        "autoscaling:SetInstanceProtection",
        "autoscaling:UpdateAutoScalingGroup"
    ]

    resources = ["*"]
  }

  statement {
    sid = "AutoScalingPlanManagement"

    actions = [
        "autoscaling-plans:CreateScalingPlan",
        "autoscaling-plans:DeleteScalingPlan",
        "autoscaling-plans:DescribeScalingPlans"
    ]

    resources = ["*"]
  }
  
    
  statement {
    sid = "CWAlarmManagement"

    actions = [
        "cloudwatch:DeleteAlarms",
        "cloudwatch:DescribeAlarms",
        "cloudwatch:PutMetricAlarm"
    ]

    resources = ["*"]
  }

  statement {
    sid = "ECSTagging"

    actions = [
        "ec2:CreateTags"
    ]

    resources = ["arn:aws:ec2:*:*:network-interface/*"]
  }
  statement {
    sid = "CWLogGroupManagement"

    actions = [
        "logs:CreateLogGroup",
        "logs:DescribeLogGroups",
        "logs:PutRetentionPolicy"
    ]

    resources = ["arn:aws:logs:*:*:log-group:/aws/ecs/*"]
  }

  statement {
    sid = "CWLogStreamManagement"

    actions = [
        "logs:CreateLogStream",
        "logs:DescribeLogStreams",
        "logs:PutLogEvents"
    ]

    resources = ["arn:aws:logs:*:*:log-group:/aws/ecs/*:log-stream:*"] 
  }
}