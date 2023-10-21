variable "region" {
  type    = string
  default = "us-east-1"
}

variable "vpc_cidr_block" {
  type    = string
  default = "10.10.0.0/16"
}

variable "availability_zones" {
  type    = list(string)
  default = ["us-east-1a", "us-east-1b"]
}

variable "public_subnets" {
  type    = list(string)
  default = ["10.10.1.0/24", "10.10.2.0/24"]
}

variable "private_subnets" {
  type    = list(string)
  default = ["10.10.3.0/24", "10.10.4.0/24", "10.10.5.0/24", "10.10.6.0/24", "10.10.7.0/24", "10.10.8.0/24"]
}

variable "public_alb_ingress_ports" {
  type = list(number)
  default = [ 80, 443 ]
}

variable "fronted_ingress_ports" {
  type = list(number)
  default = [ 80, 443, 22 ]
}

variable "private_alb_ingress_ports" {
  type = list(number)
  default = [ 80, 443 ]
}

variable "backend_ingress_ports" {
  type = list(number)
  default = [ 80, 443, 22 ]
}

variable "db_ingress_ports" {
  type = list(number)
  default = [ 3306 ]
}

variable "frontend_public_key" {
  type = string
}

variable "backend_public_key" {
  type = string
}

variable "db_name" {
  type = string
}

variable "db_username" {
  type = string
}

variable "db_password" {
  type = string
}

variable "db_instance_class" {
  type = string
  default = "db.t2.micro"
}

variable "db_engine" {
  type = string
  default = "mysql"
}

variable "db_storage" {
  type = number
  default = 20
}

variable "max_db_storage" {
  type = number
  default = 100
}