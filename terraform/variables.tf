# VPC VARS
variable "creds" {
  type    = list(string)
  default = ["/home/cs/.aws/credentials"]
}

variable "key_name" {
  type    = string
  default = "NewPair"
}

variable "region" {
  type    = string
  default = "eu-west-2"
}

variable "vpc_name" {
  type    = string
  default = "assessment2-vpc"
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "azs" {
  type    = string
  default = "eu-west-2a"
}

variable "map_public_ip" {
  type    = bool
  default = true
}

variable "enable_nat_gateway" {
  type    = bool
  default = false
}

variable "enable_vpn_gateway" {
  type    = bool
  default = false
}

variable "master_sg_name" {
  type    = string
  default = "master_sg"
}

# TARGET_SG VARS
variable "target_sg_name" {
  type    = string
  default = "target_sg"
}

# EC2 VARS
variable "ubuntu_ami" {
  type    = string
  default = "ami-09744628bed84e434"
}

