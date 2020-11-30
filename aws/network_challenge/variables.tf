# Default variables
variable "project_name" {
  type = string
}

variable "env" {
  type = string
}

variable "tags" {
  type = map(string)
}

# VPC
variable "vpc_cidr_block" {
}

variable "availability_zones" {
  type = list(string)
}

variable "subnet_newbits" {
  type = string
}