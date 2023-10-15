resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr_block

  tags = {
    Name = "main-vpc"
  }
}

resource "aws_internet_gateway" "main-igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "main-igw"
  }
}

resource "aws_subnet" "main-privates" {
  count             = length(var.private_subnets)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnets[count.index]
  availability_zone = element(var.availability_zones, count.index)

  tags = {
    Name = "private-subnet-${element(var.availability_zones, count.index)}-${count.index}"
  }
}

resource "aws_subnet" "main-publics" {
  count                   = length(var.public_subnets)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnets[count.index]
  availability_zone       = element(var.availability_zones, count.index)
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet-${element(var.availability_zones, count.index)}-${count.index}"
  }
}

resource "aws_eip" "main-eip" {
  count = length(var.availability_zones)
}

resource "aws_nat_gateway" "main-natgw" {
  count = length(length(var.availability_zones) > length(var.public_subnets) ? var.public_subnets : var.availability_zones)
  subnet_id = element(aws_subnet.main-publics[*].id, count.index)
  allocation_id = element(aws_eip.main-eip[*].id, count.index)
}

resource "aws_route_table" "public_rtb" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main-igw.id
  }

  tags = {
    Name = "public_rtb"
  }
}

resource "aws_route_table_association" "public_rtb_association" {
  count = length(var.public_subnets)
  subnet_id = aws_subnet.main-publics[count.index].id
  route_table_id = aws_route_table.public_rtb.id
}

resource "aws_route_table" "private_rtb" {
  count = length(aws_nat_gateway.main-natgw)
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = element(aws_nat_gateway.main-natgw[*].id, count.index)
  }

  tags = {
    Name = "private_rtb_${count.index}"
  }
}

resource "aws_route_table_association" "private_rtb_association" {
  count = length(var.private_subnets)
  subnet_id = element(aws_subnet.main-privates[*].id, count.index)
  route_table_id = element(aws_route_table.private_rtb[*].id, count.index)
}