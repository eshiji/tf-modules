resource "aws_subnet" "private_subnets" {
  count             = 2
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = cidrsubnet(var.vpc_cidr_block, var.subnet_newbits, count.index)
  availability_zone = element(var.availability_zone, count.index)
  depends_on        = [aws_vpc.vpc]

  tags = merge(
    {
      "Name" = format("private_subnet%d", count.index)
    },
    var.tags,
  )
}

resource "aws_subnet" "public_subnets" {
  count             = 2
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = cidrsubnet(var.vpc_cidr_block, var.subnet_newbits, 2 + count.index)
  availability_zone = element(var.availability_zone, count.index)
  depends_on        = [aws_vpc.vpc]

  tags = merge(
    {
      "Name" = format("public_subnet%d", count.index)
    },
    var.tags,
  )
}

