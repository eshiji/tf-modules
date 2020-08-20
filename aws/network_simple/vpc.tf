#######
# VPC #
#######
resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_hostnames = "true"

  tags = merge(
    {
      "Name" = "VPC_${var.project_name}_${var.env}"
    },
    var.tags,
  )
}

####################
# Internet Gateway #
####################
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = merge(
    {
      "Name" = "IGW_${var.project_name}_${var.env}"
    },
    var.tags,
  )
}

###############
# Egress IPV6 #
###############
resource "aws_egress_only_internet_gateway" "egress_only" {
  vpc_id = aws_vpc.vpc.id
}

#############
# EIP NAT 1 #
#############
resource "aws_eip" "eip_nat_gtw1" {
  vpc = true

  tags = merge(
    {
      "Name" = "EIP_NAT_GTW_${var.project_name}_${var.env}"
    },
    var.tags,
  )
}

#################
# NAT GATEWAY 1 #
#################
resource "aws_nat_gateway" "nat_gtw1" {
  allocation_id = aws_eip.eip_nat_gtw1.id
  subnet_id     = aws_subnet.public_subnets[0].id

  tags = merge(
    {
      "Name" = "NAT_GTW_${var.project_name}_${var.env}"
    },
    var.tags,
  )
}

#############
# EIP NAT 2 #
#############
resource "aws_eip" "eip_nat_gtw2" {
  vpc = true

  tags = merge(
    {
      "Name" = "EIP_NAT_GTW_${var.project_name}_${var.env}"
    },
    var.tags,
  )
}

#################
# NAT GATEWAY 2 #
#################
resource "aws_nat_gateway" "nat_gtw2" {
  allocation_id = aws_eip.eip_nat_gtw2.id

  #subnet_id     = "${aws_subnet.pub_ecare_all_dmz_sit_useast1a.id}"
  subnet_id = aws_subnet.public_subnets[1].id

  tags = merge(
    {
      "Name" = "NAT_GTW_${var.project_name}_${var.env}"
    },
    var.tags,
  )
}

