# Common
variable "project_name" {
}

variable "env" {
}

variable "tags" {
  type = map(string)
}

# Network vars
variable "vpc_id" {
}

variable "public_subnets_id" {
  type = list(string)
}

variable "private_subnets_id" {
  type = list(string)
}

# Launch configuration
variable "ecs_instance_ami" {
}

variable "ec2_instance_type" {
}

variable "ec2_pub_key" {
}

# Auto Scaling Group
variable "asg_instances_max_count" {
}

variable "asg_instances_min_count" {
}

variable "asg_instances_desired_count" {
}

variable "asg_cpu_scaling_metric_target" {
}

# ALB
# variable "certificate_arn" {}
variable "cidr_block_whitelist" {
  type = list(string)
}

