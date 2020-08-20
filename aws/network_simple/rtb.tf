################
# Public rtb 1 #
################
resource "aws_route_table" "rtb_pub1" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  route {
    ipv6_cidr_block        = "::/0"
    egress_only_gateway_id = aws_egress_only_internet_gateway.egress_only.id
  }

  tags = merge(
    {
      "Name" = "RTB_PUB_${var.project_name}_${var.env}"
    },
    var.tags,
  )
}

#################
# Private rtb 1 #
#################
resource "aws_route_table" "rtb_priv1" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gtw1.id
  }

  tags = merge(
    {
      "Name" = "RTB_PRIV1_${var.project_name}_${var.env}"
    },
    var.tags,
  )
}

#################
# Private rtb 2 #
#################
resource "aws_route_table" "rtb_priv2" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gtw2.id
  }

  tags = merge(
    {
      "Name" = "RTB_PRIV2_${var.project_name}_${var.env}"
    },
    var.tags,
  )
}

############################################
# PUB SUBNETS 1 ASSOCIATION WITH RTB PUB 1 #
############################################
resource "aws_route_table_association" "pub_subnets1_association_pub_rtb1" {
  count          = 2
  subnet_id      = aws_subnet.public_subnets[count.index].id
  route_table_id = aws_route_table.rtb_pub1.id
}

##############################################
# PRIV SUBNETS 1 ASSOCIATION WITH RTB PRIV 1 #
##############################################
resource "aws_route_table_association" "priv_subnet1_association_priv_rtb1" {
  subnet_id      = aws_subnet.private_subnets[0].id
  route_table_id = aws_route_table.rtb_priv1.id
}

#############################################
# PRIV SUBNET 2 ASSOCIATION WITH RTB PRIV 2 #
#############################################
resource "aws_route_table_association" "priv_subnet2_association_priv_rtb2" {
  subnet_id      = aws_subnet.private_subnets[1].id
  route_table_id = aws_route_table.rtb_priv2.id
}

