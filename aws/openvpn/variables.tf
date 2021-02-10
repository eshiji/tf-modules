# Common
variable "project_name" {
  type = string
}
variable "env" {
  type    = string
  default = "dev"
}
variable "tags" {
  type = map(string)
}

# Launch template and ASG
variable "launch_template_ebs_size" {
  type    = number
  default = 8
}
variable "launch_template_device_name" {
  type    = string
  default = "/dev/sda1"
}

variable "launch_template_monitoring" {
  type    = bool
  default = false
}

variable "launch_template_termination_protection" {
  type    = bool
  default = false
}

variable "launch_template_associate_public_ip_address" {
  type    = bool
  default = true
}
variable "launch_template_delete_eni_on_termination" {
  type    = bool
  default = true
}

variable "launch_template_instance_type" {
  type = string
}

variable "launch_template_key_pair_name" {
  type = string
}

# ASG
variable "asg_max_size" {
  type = number
}
variable "asg_min_size" {
  type = number
}
variable "asg_desired_capacity" {
  type = number
}

# Network
variable "vpc_id" {
  type = string
}
variable "public_subnet_ids" {
  type = list(string)
}
variable "cidr_block_whitelist" {
  type = list(string)
}