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


# ALB
# variable "certificate_arn" {}
variable "cidr_block_whitelist" {
  type = list(string)
}

