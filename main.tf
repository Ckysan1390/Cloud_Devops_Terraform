terraform {
    required_providers {
        aws = {
            source = "hashicorp/aws"
            version = "~> 5.0"
        }
    }
}

provider "aws" {
    region = "us-east-1"
    profile = "terraform"
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "main"
  cidr = "10.0.0.0/16"

  azs             = ["us-east-1a"]
  private_subnets = ["10.0.1.0/24"]
  public_subnets  = ["10.0.101.0/24"]

  tags = {
    Terraform = "true"
    Environment = "dev"
  }
}

resource "aws_instance" "private-instance" {
  count             = 2

  ami               = "ami-0953476d60561c955"
  instance_type     = "t2.micro"

  subnet_id         = module.vpc.private_subnets[0]
  availability_zone = "us-east-1a"
  security_groups = [aws_security_group.allow_ssh_sg.id]

  tags = {
    Name = "private-instance-${count.index}"
  }
}

resource "aws_security_group" "allow_ssh_sg" {
  name = "allow_ssh_sg"
  description = "Allow SSH from anywhere"
  vpc_id = module.vpc.vpc_id

  tags = {
    name = "allow_ssh_sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_ssh_rule" {
  security_group_id = aws_security_group.allow_ssh_sg.id
  
  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 22
  ip_protocol = "tcp"
  to_port     = 22
}

resource "aws_vpc_security_group_egress_rule" "allow_all_rule" {
  security_group_id = aws_security_group.allow_ssh_sg.id
  
  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 0
  ip_protocol = "-1"
  to_port     = 0
}