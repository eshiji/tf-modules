# AMI ID
output "aws_ami_id" {
  value = data.aws_ami.ubuntu.id
}

# Launch Template
output "launch_template_id" {
  value = aws_launch_template.launch_template.id
}

output "launch_template_arn" {
  value = aws_launch_template.launch_template.arn
}

output "launch_template_latest_version" {
  value = aws_launch_template.launch_template.latest_version
}

# Instance profile
output "instance_profile_id" {
  value = aws_iam_instance_profile.ec2_instance_profile.id
}

output "instance_profile_unique_id" {
  value = aws_iam_instance_profile.ec2_instance_profile.unique_id
}

output "instance_profile_path" {
  value = aws_iam_instance_profile.ec2_instance_profile.path
}

output "instance_profile_name" {
  value = aws_iam_instance_profile.ec2_instance_profile.name
}

output "instance_profile_role" {
  value = aws_iam_instance_profile.ec2_instance_profile.role
}

# IAM Role
output "ec2_role_arn" {
  value = aws_iam_role.ec2_role.arn
}

output "ec2_role_id" {
  value = aws_iam_role.ec2_role.id
}

output "ec2_role_name" {
  value = aws_iam_role.ec2_role.name
}

# Security Group
output "security_group_id" {
  value = aws_security_group.ec2_sg.id
}

output "security_group_name" {
  value = aws_security_group.ec2_sg.name
}

output "security_group_vpc_id" {
  value = aws_security_group.ec2_sg.vpc_id
}

output "security_group_ingress" {
  value = aws_security_group.ec2_sg.ingress
}

output "security_group_egress" {
  value = aws_security_group.ec2_sg.egress
}

# Autoscaling Group (ASG)
output "asg_id" {
  value = aws_autoscaling_group.asg.id
}

output "asg_arn" {
  value = aws_autoscaling_group.asg.arn
}

output "asg_name" {
  value = aws_autoscaling_group.asg.name
}

output "asg_min_size" {
  value = aws_autoscaling_group.asg.min_size
}

output "asg_max_size" {
  value = aws_autoscaling_group.asg.max_size
}