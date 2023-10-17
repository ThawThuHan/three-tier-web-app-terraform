variable "region" {
  type    = string
  default = "us-east-1"
}

variable "vpc_cidr_block" {
  type    = string
  default = "10.10.0.0/16"
}

variable "public_subnets" {
  type    = list(string)
  default = ["10.10.1.0/24", "10.10.2.0/24"]
}

variable "private_subnets" {
  type    = list(string)
  default = ["10.10.3.0/24", "10.10.4.0/24", "10.10.5.0/24", "10.10.6.0/24"]
}

variable "availability_zones" {
  type    = list(string)
  default = ["us-east-1a", "us-east-1b"]
}

variable "public_alb_ingress_ports" {
  type = list(number)
  default = [ 80, 443 ]
}

variable "fronted_ingress_ports" {
  type = list(number)
  default = [ 80, 443 ]
}

variable "private_alb_ingress_ports" {
  type = list(number)
  default = [ 80, 443 ]
}

variable "backend_ingress_ports" {
  type = list(number)
  default = [ 80, 443 ]
}

# variable "frontend_public_key" {
#   type = string
# }

# variable "backend_public_key" {
#   type = string
# }