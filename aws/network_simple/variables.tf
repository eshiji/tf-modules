# Default variables
variable "project_name" {
}

variable "env" {
  type = list(string)
}

variable "tags" {
  type = map(string)
}


# VPC 
variable "vpc_cidr_block" {
}


variable "availability_zone" {
  type = list(string)
}

variable "subnet_priv_names" {
  type = list(string)
}

variable "subnet_dmz_pub_names" {
  type = list(string)
}

variable "subnet_lb_pub_names" {
  type = list(string)
}

variable "subnet_db_priv_names" {
  type = list(string)
}

