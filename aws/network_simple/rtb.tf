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
      "Name" = "RTB_PUB_${var.project_name}_${element(var.env, 1)}"
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
      "Name" = "RTB_PRIV_${var.project_name}_${element(var.env, 1)}"
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
      "Name" = "RTB_PRIV_${var.project_name}_${element(var.env, 2)}"
    },
    var.tags,
  )
}

#########################
# Get all pub subnets 1 #
#########################
data "aws_subnet_ids" "subnets_pub1" {
  vpc_id = aws_vpc.vpc.id
  depends_on = [
    aws_subnet.subnets_pub_dmz,
    aws_subnet.subnets_pub_lb,
  ]

  filter {
    name   = "tag:Name"
    values = ["*_all_dmz_pub1_*", "*_all_lb_pub1_*"]
  }
}

############################################
# PUB SUBNETS 1 ASSOCIATION WITH RTB PUB 1 #
############################################
resource "aws_route_table_association" "pub_subnets1_association_pub_rtb1" {
  count          = 4
  subnet_id      = element(tolist(data.aws_subnet_ids.subnets_pub1.ids), count.index)
  route_table_id = aws_route_table.rtb_pub1.id
  depends_on     = [data.aws_subnet_ids.db_subnets1]
}

##########################
# Get all priv subnets 1 #
##########################
data "aws_subnet_ids" "subnets_priv1" {
  vpc_id = aws_vpc.vpc.id
  depends_on = [
    aws_subnet.subnets_priv,
    aws_subnet.subnets_priv_db,
  ]

  filter {
    name   = "tag:Name"
    values = ["*_all_dmz_priv1_*", "*_all_app_priv1_*", "*_bd_priv1_*"]
  }
}

##############################################
# PRIV SUBNETS 1 ASSOCIATION WITH RTB PRIV 1 #
##############################################
resource "aws_route_table_association" "priv_subnet1_association_priv_rtb1" {
  count          = 6
  subnet_id      = element(tolist(data.aws_subnet_ids.subnets_priv1.ids), count.index)
  route_table_id = aws_route_table.rtb_priv1.id
}

#########################
# Get all pub subnets 2 #
#########################
data "aws_subnet_ids" "subnets_pub2" {
  vpc_id = aws_vpc.vpc.id
  depends_on = [
    aws_subnet.subnets_pub_dmz,
    aws_subnet.subnets_pub_lb,
  ]

  filter {
    name   = "tag:Name"
    values = ["*_all_dmz_pub2_*", "*_all_lb_pub2_*"]
  }
}

###########################################
# PUB SUBNET 2 ASSOCIATION WITH RTB PUB 2 #
###########################################
resource "aws_route_table_association" "pub_subnet2_association_pub_rtb2" {
  count          = 4
  subnet_id      = element(tolist(data.aws_subnet_ids.subnets_pub2.ids), count.index)
  route_table_id = aws_route_table.rtb_pub2.id
}

##########################
# Get all priv subnets 2 #
##########################
data "aws_subnet_ids" "subnets_priv2" {
  vpc_id = aws_vpc.vpc.id
  depends_on = [
    aws_subnet.subnets_priv,
    aws_subnet.subnets_priv_db,
  ]

  filter {
    name   = "tag:Name"
    values = ["*_all_dmz_priv2_*", "*_all_app_priv2_*", "*_bd_priv2_*"]
  }
}

#############################################
# PRIV SUBNET 2 ASSOCIATION WITH RTB PRIV 2 #
#############################################
resource "aws_route_table_association" "priv_subnet2_association_priv_rtb2" {
  count          = 6
  subnet_id      = element(tolist(data.aws_subnet_ids.subnets_priv2.ids), count.index)
  route_table_id = aws_route_table.rtb_priv2.id
}

