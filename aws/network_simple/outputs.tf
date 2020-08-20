output "vpc_id" {
  value = aws_vpc.vpc.id
}

output "private_subnets_ids" {
  value = aws_subnet.private_subnets.*.id
}

output "public_subnets_ids" {
  value = aws_subnet.public_subnets.*.id
}

output "rtb_pub1" {
  value = aws_route_table.rtb_pub1.id
}

output "rtb_priv1" {
  value = aws_route_table.rtb_priv1.id
}

output "rtb_priv2" {
  value = aws_route_table.rtb_priv2.id
}

output "nat_gtw1" {
  value = aws_nat_gateway.nat_gtw1.id
}

output "nat_gtw2" {
  value = aws_nat_gateway.nat_gtw2.id
}

output "eip1" {
  value = aws_eip.eip_nat_gtw1.id
}

output "eip2" {
  value = aws_eip.eip_nat_gtw2.id
}

output "igw" {
  value = aws_internet_gateway.igw.id
}

output "egress_only_internet_gateway" {
  value = aws_egress_only_internet_gateway.egress_only.id
}

