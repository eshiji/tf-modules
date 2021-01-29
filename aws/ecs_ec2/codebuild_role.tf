# Create iam policy for codebuild_service_role
resource "aws_iam_policy" "codebuild_service_policy" {
  name   = "${var.env}-${var.project_name}-codebuild-service-policy"
  path   = "/"
  policy = data.aws_iam_policy_document.codebuild_service_role_policy.json
}

# Create Codebuild service role
resource "aws_iam_role" "codebuild_service_role" {
  name                  = "${var.project_name}-${var.env}-codebuild-service-role"
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
          "codebuild.amazonaws.com"
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

data "aws_iam_policy_document" "codebuild_service_role_policy" {
  statement {
    actions = [
      "codebuild:StartBuild",
      "codebuild:StopBuild",
      "codebuild:BatchGet*",
      "codebuild:GetResourcePolicy",
      "codebuild:DescribeTestCases",
      "codebuild:List*",
      "codecommit:GetBranch",
      "codecommit:GetCommit",
      "codecommit:GetRepository",
      "codecommit:ListBranches",
      "cloudwatch:GetMetricStatistics",
      "events:DescribeRule",
      "events:ListTargetsByRule",
      "events:ListRuleNamesByTarget",
      "logs:GetLogEvents",
      "s3:*",
      "logs:*",
      "ecr:*"
    ]

    resources = ["*"]
  }

  statement {
    actions = [
      "ssm:PutParameter"
    ]

    resources = ["arn:aws:ssm:*:*:parameter/CodeBuild/*"]
  }

  statement {
    sid = "CodeStarNotificationsReadWriteAccess"

    actions = [
      "codestar-notifications:CreateNotificationRule",
      "codestar-notifications:DescribeNotificationRule",
      "codestar-notifications:UpdateNotificationRule",
      "codestar-notifications:Subscribe",
      "codestar-notifications:Unsubscribe"
    ]

    resources = ["*"]

    condition {
      test = "StringLike"
      variable = "codestar-notifications:NotificationsForResource" 
      
      values = ["arn:aws:codebuild:*"]
    }
  }

  statement {
    sid = "CodeStarNotificationsListAccess"
  
    actions = [
      "codestar-notifications:ListNotificationRules",
      "codestar-notifications:ListEventTypes",
      "codestar-notifications:ListTargets",
      "codestar-notifications:ListTagsforResource"
    ]

    resources = ["*"]
  }

  statement {
    sid = "sns"

    actions = [
      "sns:ListTopics",
      "sns:GetTopicAttributes"
    ]

    resources = ["*"]
  }
}

