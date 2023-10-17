# Creating VPC
resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr_block

  tags = {
    Name = "main-vpc"
  }
}

#Creating Internet Gateway
resource "aws_internet_gateway" "main-igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "main-igw"
  }
}

#Creating Public and Private Subnet
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

#Creating Elastic IP
resource "aws_eip" "main-eip" {
  count = length(var.availability_zones)
}

#Creating NAT Gateway
resource "aws_nat_gateway" "main-natgw" {
  count = length(length(var.availability_zones) > length(var.public_subnets) ? var.public_subnets : var.availability_zones)
  subnet_id = element(aws_subnet.main-publics[*].id, count.index)
  allocation_id = element(aws_eip.main-eip[*].id, count.index)
}

#Creating Route Table for Public and Private Subnets
resource "aws_route_table" "public-rtb" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main-igw.id
  }

  tags = {
    Name = "public_rtb"
  }
}

resource "aws_route_table_association" "public-rtb-association" {
  count = length(var.public_subnets)
  subnet_id = aws_subnet.main-publics[count.index].id
  route_table_id = aws_route_table.public-rtb.id
}

resource "aws_route_table" "private-rtb" {
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

resource "aws_route_table_association" "private-rtb-association" {
  count = length(var.private_subnets)
  subnet_id = element(aws_subnet.main-privates[*].id, count.index)
  route_table_id = element(aws_route_table.private-rtb[*].id, count.index)
}

#Creating Security Group for public facing ALB
resource "aws_security_group" "public-alb-sg" {
  name = "public-alb-sg"
  description = "allow HTTP and HTTPS traffic from internet"
  vpc_id = aws_vpc.main.id

  dynamic "ingress" {
    for_each = var.public_alb_ingress_ports
    content {
      from_port = ingress.value
      to_port = ingress.value
      protocol = "tcp"
      cidr_blocks = [ "0.0.0.0/0" ]
    }
  }
}

#Creating Security Group for frontend ASG
resource "aws_security_group" "frontend-sg" {
  name = "frontend-sg"
  description = "allow HTTP and HTTPS traffic from public-alb-sg"
  vpc_id = aws_vpc.main.id

  dynamic "ingress" {
    for_each = var.fronted_ingress_ports
    content {
      from_port = ingress.value
      to_port = ingress.value
      protocol = "tcp"
      security_groups = [ aws_security_group.public-alb-sg.id ]
    }
  }
}

#Creating Security Group for Private ALB
resource "aws_security_group" "private-alb-sg" {
  name = "private-alb-sg"
  description = "allow HTTP and HTTPS from frontend-sg"
  vpc_id = aws_vpc.main.id

  dynamic "ingress" {
    for_each = var.private_alb_ingress_ports
    content {
      from_port = ingress.value
      to_port = ingress.value
      protocol = "tcp"
      security_groups = [ aws_security_group.frontend-sg.id ]
    }
  }
}

#Creating Security Group for backend ASG
resource "aws_security_group" "backend-sg" {
  name = "backend-sg"
  description = "allow HTTP and HTTPS from private-alb-sg"
  vpc_id = aws_vpc.main.id

  dynamic "ingress" {
    for_each = var.backend_ingress_ports
    content {
      from_port = ingress.value
      to_port = ingress.value
      protocol = "tcp"
      security_groups = [ aws_security_group.private-alb-sg.id ]
    }
  }
}

data "aws_ami" "amazon-latest-ami" {
  most_recent = true

  filter {
    name = "name"
    values = [ "al2023-ami-2023.2.20231016.0-kernel-6.1-x86_64" ]
  }

  filter {
    name = "owner-alias"
    values = [ "amazon" ]
  }

  filter {
    name = "virtualization-type"
    values = [ "hvm" ]
  }

  filter {
    name = "root-device-type"
    values = [ "ebs" ]
  }

  filter {
    name = "architecture"
    values = [ "x86_64" ]
  }
}

#Creating AWS Key Pair for frontend
resource "aws_key_pair" "frontend-keypair" {
  key_name = "frontend-keypair"
  public_key = file("./frontend.pub")
}

#Creating AWS Key Pair for backend
resource "aws_key_pair" "backend-keypair" {
  key_name = "frontend-keypair"
  public_key = file("./backend.pub")
}

# Creating EC2 Launch Template for ASG
resource "aws_launch_template" "frontend" {
  name_prefix = "frontend-launch-template"
  image_id = data.aws_ami.amazon-latest-ami.id
  instance_type = "t2.micro"
  user_data = file("./user-data.sh")
  security_group_names = [ aws_security_group.frontend-sg.name ]
  key_name = aws_key_pair.frontend-keypair.key_name
}

#Creating ASG
resource "aws_autoscaling_group" "frontend-asg" {
  name = "frontend-asg"
  max_size = 3
  min_size = 1
  desired_capacity = 2
  launch_template {
    id = aws_launch_template.frontend.id
    version = "$latest"
  }
}