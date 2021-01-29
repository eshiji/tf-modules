# Create iam policy for codepipeline_service_role
resource "aws_iam_policy" "codepipeline_service_policy" {
  name   = "${var.env}-${var.project_name}-codepipeline-service-policy"
  path   = "/"
  policy = data.aws_iam_policy_document.codepipeline_service_role_policy.json
}

# Create ecs service role
resource "aws_iam_role" "codepiline_service_role" {
  name                  = "${var.project_name}-${var.env}-codepipeline-service-role"
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
          "codepipeline.amazonaws.com"
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
data "aws_iam_policy_document" "codepipeline_service_role_policy" {
  statement {
    actions = [
        "cloudformation:CreateStack",
        "cloudformation:DeleteStack",
        "cloudformation:DescribeStacks",
        "cloudformation:UpdateStack",
        "cloudformation:CreateChangeSet",
        "cloudformation:DeleteChangeSet",
        "cloudformation:DescribeChangeSet",
        "cloudformation:ExecuteChangeSet",
        "cloudformation:SetStackPolicy",
        "cloudformation:ValidateTemplate",
        "iam:PassRole",
        "s3:*",
    ]

    resources = ["*"]
  }

  statement {
    sid = "Codebuild"

    actions = [
        "codebuild:BatchGetBuilds",
        "codebuild:StartBuild"
    ]

    resources = ["*"]
  }

  statement {
    sid = "ECR"

    actions = [
        "ecr:*"
    ]

    resources = ["*"]
  }
  
    
  statement {
    sid = "ECS"

    actions = [
        "ecs:DescribeServices",
        "ecs:DescribeTaskDefinition",
        "ecs:DescribeTasks",
        "ecs:ListTasks",
        "ecs:RegisterTaskDefinition",
        "ecs:UpdateService"
    ]

    resources = ["*"]
  }

  statement {
    sid = "CodeDeploy"

    actions = [
        "codedeploy:CreateDeployment",
        "codedeploy:GetDeployment",
        "codedeploy:GetApplication",
        "codedeploy:GetApplicationRevision",
        "codedeploy:RegisterApplicationRevision",
        "codedeploy:GetDeploymentConfig",
        "ecs:RegisterTaskDefinition",
        "iam:PassRole"
    ]

    resources = ["*"]
  }
}
