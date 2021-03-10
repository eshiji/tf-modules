# AMI ID
output "aws_ami_id" {
  value = data.aws_ami.ubuntu.id
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


