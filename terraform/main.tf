# PROVIDERS ---------------------------------------------------------------------------------------
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.66.1"
    }
  }
}

provider "aws" {
  shared_credentials_files = var.creds
  profile                  = "default"
  region                   = var.region
}

# VPC ---------------------------------------------------------------------------------------
module "vpc" {
  source                      = "terraform-aws-modules/vpc/aws"
  name                        = var.vpc_name
  cidr                        = var.vpc_cidr
  azs                         = [var.azs]
  public_subnets              = ["10.0.101.0/24"]
  map_public_ip_on_launch     = var.map_public_ip
  enable_nat_gateway          = var.enable_nat_gateway
  enable_vpn_gateway          = var.enable_vpn_gateway
  default_security_group_name = var.master_sg_name

  default_security_group_ingress = [{
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    description = "Master SSH Ingress"
    cidr_blocks = "0.0.0.0/0"
  }]
  default_security_group_egress = [{
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    description = "Master SSH Egress"
    cidr_blocks = "0.0.0.0/0"
  }]
  default_security_group_tags = {
    Name = var.master_sg_name
  }

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

# TARGET_SEC_GROUP -----------------------------------------------------------------------------
module "target_sg" {
  source = "terraform-aws-modules/security-group/aws"
  name   = var.target_sg_name
  vpc_id = module.vpc.vpc_id

  ingress_with_cidr_blocks = [
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      from_port   = 9876
      to_port     = 9876
      protocol    = "tcp"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      rule        = "postgresql-tcp"
      cidr_blocks = "0.0.0.0/0"
  }]
  egress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = "0.0.0.0/0"
  }]
}

# EC2 ---------------------------------------------------------------------------------------
module "master_node" {
  source                 = "terraform-aws-modules/ec2-instance/aws"
  name                   = "master_node"
  instance_type          = "t2.micro"
  key_name               = var.key_name
  monitoring             = false
  vpc_security_group_ids = [module.vpc.default_security_group_id]
  subnet_id              = element(module.vpc.public_subnets, 0)
  availability_zone      = var.azs
  ami                    = var.ubuntu_ami

  user_data = <<-EOF
  #!/bin/bash
  sudo apt update -y
  sudo apt upgrade -y
  EOF

  tags = {
    Name        = "master_node"
    Terraform   = "true"
    Environment = "dev"
  }
}

module "target_nodes" {
  source = "terraform-aws-modules/ec2-instance/aws"
  count  = 2
  name   = "target_node_${count.index}"

  instance_type               = "t2.micro"
  key_name                    = var.key_name
  monitoring                  = false
  vpc_security_group_ids      = [module.target_sg.security_group_id]
  subnet_id                   = element(module.vpc.public_subnets, 0)
  associate_public_ip_address = true
  availability_zone           = var.azs
  ami                         = var.ubuntu_ami

  user_data = <<-EOF
  #!/bin/bash
  sudo apt update -y
  sudo apt upgrade -y
  EOF

  tags = {
    Name        = "target_node_${count.index}"
    Terraform   = "true"
    Environment = "dev"
  }
}
