#Providers
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region  = "us-east-1"
  profile = "terraform"
}

#Network
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "main"
  cidr = "10.0.0.0/16"

  azs             = ["us-east-1a", "us-east-1b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}



#Role
resource "aws_iam_role" "ssm_instance_role" {
  name = "ssm-instance-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })

  tags = {
    Name = "SSM-Enabled-EC2-Role"
  }
}

resource "aws_iam_role_policy_attachment" "ssm_policy_attach" {
  role       = aws_iam_role.ssm_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ssm_instance_profile" {
  name = "ssm-instance-profile"
  role = aws_iam_role.ssm_instance_role.name
}

#EC2 Instances
resource "aws_instance" "web-server" {
  count = 2

  ami                  = "ami-0953476d60561c955"
  instance_type        = "t2.micro"
  subnet_id            = module.vpc.private_subnets[0]
  availability_zone    = "us-east-1a"
  security_groups      = [aws_security_group.ssm_sg.id]
  iam_instance_profile = aws_iam_instance_profile.ssm_instance_profile.name
  user_data            = <<-EOF
              #!/bin/bash
              sudo yum update -y
              sudo yum install -y httpd
              sudo systemctl start httpd
              sudo systemctl enable httpd
              sudo touch /var/www/html/index.html
              echo "<h1>Hello World from EPAM's Terraform Course</h1>" > /var/www/html/index.html
              EOF

  tags = {
    Name = "web-server-${count.index}"
  }
}

#security groups
resource "aws_security_group" "ssm_sg" {
  name        = "allow_ssm"
  description = "Allow connection to SSM"
  vpc_id      = module.vpc.vpc_id

  tags = {
    Name = "ssm-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_https" {
  security_group_id = aws_security_group.ssm_sg.id
  cidr_ipv4         = "10.0.1.0/24"
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}

resource "aws_vpc_security_group_ingress_rule" "allow_http" {
  security_group_id            = aws_security_group.ssm_sg.id
  referenced_security_group_id = aws_security_group.ssm_sg.id
  ip_protocol                  = "-1"
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.ssm_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

#SSM Endpoints
resource "aws_vpc_endpoint" "ssm_endpoint" {
  vpc_id              = module.vpc.vpc_id
  subnet_ids          = module.vpc.private_subnets
  service_name        = "com.amazonaws.us-east-1.ssm"
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [aws_security_group.ssm_sg.id]
  private_dns_enabled = true

  tags = {
    Name = "ssm-endpoint"
  }
}

resource "aws_vpc_endpoint" "ssmmessages_endpoint" {
  vpc_id              = module.vpc.vpc_id
  subnet_ids          = module.vpc.private_subnets
  service_name        = "com.amazonaws.us-east-1.ssmmessages"
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [aws_security_group.ssm_sg.id]
  private_dns_enabled = true

  tags = {
    Name = "ssmmessages-endpoint"
  }
}

resource "aws_vpc_endpoint" "ec2messages_endpoint" {
  vpc_id              = module.vpc.vpc_id
  subnet_ids          = module.vpc.private_subnets
  service_name        = "com.amazonaws.us-east-1.ec2messages"
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [aws_security_group.ssm_sg.id]
  private_dns_enabled = true

  tags = {
    Name = "ec2messages-endpoint"
  }
}