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

locals {
  double_length_az = length(var.availability_zones) * 2
}

#Creating Public and Private Subnet
resource "aws_subnet" "main-privates" {
  count             = length(var.private_subnets)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnets[count.index]
  availability_zone = element(var.availability_zones, count.index)

  tags = {
    Name = "private-subnet-${count.index < length(var.availability_zones) ? "frontend" : ( count.index < local.double_length_az ? "backend" : "db" )}-${element(var.availability_zones, count.index)}"
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

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
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

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
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

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
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

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

#Creating Security Group for backend ASG
resource "aws_security_group" "db-sg" {
  name = "db-sg"
  description = "allow DB port from backend-sg"
  vpc_id = aws_vpc.main.id

  dynamic "ingress" {
    for_each = var.db_ingress_ports
    content {
      from_port = ingress.value
      to_port = ingress.value
      protocol = "tcp"
      security_groups = [ aws_security_group.backend-sg.id ]
    }
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_security_group" "bastion-host-sg" {
  name = "bastion-host-sg"
  description = "allow SSH from public"
  vpc_id = aws_vpc.main.id

  ingress {
      from_port = 22
      to_port = 22
      protocol = "tcp"
      cidr_blocks = [ "0.0.0.0/0" ]
      ipv6_cidr_blocks = [ "::/0" ]
    }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
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
  public_key = file("${var.frontend_public_key}")
}

#Creating AWS Key Pair for backend
resource "aws_key_pair" "backend-keypair" {
  key_name = "backend-keypair"
  public_key = file("${var.backend_public_key}")
}

# Creating EC2 Launch Template for frontend ASG
resource "aws_launch_template" "frontend" {
  name_prefix = "frontend-launch-template"
  image_id = data.aws_ami.amazon-latest-ami.id
  instance_type = "t2.micro"
  user_data = "${base64encode(file("./script-file/frontend.sh"))}"
  vpc_security_group_ids = [ aws_security_group.frontend-sg.id ]
  key_name = aws_key_pair.frontend-keypair.key_name
}

#Creating Frontend ASG
resource "aws_autoscaling_group" "frontend-asg" {
  name = "frontend-asg"
  max_size = 3
  min_size = 1
  desired_capacity = 2
  vpc_zone_identifier = [ for subnet in aws_subnet.main-privates : subnet.id if strcontains(subnet.tags.Name, "frontend") ]
  launch_template {
    id = aws_launch_template.frontend.id
    version = "$Latest"
  }
  target_group_arns = [ aws_lb_target_group.frontend-tg.arn ]

  lifecycle {
    create_before_destroy = true
  }
}

# Creating EC2 Launch Template for backend ASG
resource "aws_launch_template" "backend" {
  name_prefix = "backend-launch-template"
  image_id = data.aws_ami.amazon-latest-ami.id
  instance_type = "t2.micro"
  user_data = "${base64encode(file("./script-file/backend.sh"))}"
  vpc_security_group_ids = [ aws_security_group.backend-sg.id ]
  key_name = aws_key_pair.backend-keypair.key_name
}

#Creating backend ASG
resource "aws_autoscaling_group" "backend-asg" {
  name = "backend-asg"
  max_size = 3
  min_size = 1
  desired_capacity = 2
  vpc_zone_identifier = [ for subnet in aws_subnet.main-privates : subnet.id if strcontains(subnet.tags.Name, "backend") ]
  launch_template {
    id = aws_launch_template.backend.id
    version = "$Latest"
  }
  target_group_arns = [ aws_lb_target_group.backend-tg.arn ]

  lifecycle {
    create_before_destroy = true
  }
}

# Frontend ALB
resource "aws_lb" "frontend-alb" {
  name = "frontend-alb"
  load_balancer_type = "application"
  security_groups = [ aws_security_group.public-alb-sg.id ]
  subnets = [ for subnet in aws_subnet.main-publics : subnet.id ]
}

resource "aws_lb_target_group" "frontend-tg" {
  name     = "frontend-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
}

resource "aws_lb_listener" "frontend-listener" {
  load_balancer_arn = aws_lb.frontend-alb.arn
  port = 80
  protocol = "HTTP"

  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.frontend-tg.arn
  }
}

# Backend ALB
resource "aws_lb" "backend-alb" {
  name = "backend-alb"
  internal = true
  load_balancer_type = "application"
  security_groups = [ aws_security_group.private-alb-sg.id ]
  subnets = [ for subnet in aws_subnet.main-privates : subnet.id if strcontains(subnet.tags.Name, "frontend") ]
}

resource "aws_lb_target_group" "backend-tg" {
  name     = "backend-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
}

resource "aws_lb_listener" "backend-listener" {
  load_balancer_arn = aws_lb.backend-alb.arn
  port = 80
  protocol = "HTTP"

  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.backend-tg.arn
  }
}

# Bastion-host
resource "aws_instance" "bastion-host" {
  ami = data.aws_ami.amazon-latest-ami.id
  instance_type = "t2.micro"
  vpc_security_group_ids = [ aws_security_group.bastion-host-sg.id ]
  key_name = aws_key_pair.frontend-keypair.key_name
  subnet_id = aws_subnet.main-publics[0].id
}

# Amazon RDS
resource "aws_db_subnet_group" "db-subnet-group" {
  name = "db-subnet"
  subnet_ids = [ for subnet in aws_subnet.main-privates : subnet.id if strcontains(subnet.tags.Name, "db") ]
}

resource "aws_db_instance" "db" {
  instance_class = var.db_instance_class
  engine = var.db_engine
  allocated_storage = var.db_storage
  max_allocated_storage = var.max_db_storage
  db_name = var.db_name
  username = var.db_username
  password = var.db_password
  multi_az = true
  vpc_security_group_ids = [ aws_security_group.db-sg.id ]
  db_subnet_group_name = aws_db_subnet_group.db-subnet-group.name
  publicly_accessible = false
  skip_final_snapshot = true
}