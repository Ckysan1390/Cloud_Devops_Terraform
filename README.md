# Cloud_Devops_Terraform

**Project Overview**

This project provides a Terraform-based infrastructure as code (IaC) solution for deploying a highly available web server setup on AWS. It leverages Amazon EC2 instances in private subnets for enhanced security, AWS Systems Manager (SSM) for secure remote management without SSH, and an Elastic Load Balancing (ELB) Classic Load Balancer for distributing traffic and ensuring high availability.

The web servers are configured to serve a simple "Hello World" page using Apache HTTPD.


**Architecture**

The architecture consists of the following AWS components:

- **VPC:** A custom Virtual Private Cloud with public and private subnets across two Availability Zones (us-east-1a, us-east-1b) for high availability.
- **NAT Gateway:** Deployed in a public subnet to allow instances in private subnets to initiate outbound connections (e.g., for system updates, package downloads) without direct internet ingress.
- **EC2 Instances:** Two t2.micro instances deployed in the private subnets, running Amazon Linux 2023 and configured with Apache HTTPD.
- **IAM Role & Instance Profile:** An IAM role with AmazonSSMManagedInstanceCore policy attached, assigned to the EC2 instances via an instance profile, enabling secure management through AWS Systems Manager.
- **VPC Endpoints:** Interface endpoints for ssm, ssmmessages, and ec2messages services are created in the private subnets. These ensure that SSM traffic from EC2 instances to AWS SSM services remains entirely within the AWS network, enhancing security and performance.
- **Classic Load Balancer:** An internet-facing load balancer deployed in the public subnets to distribute incoming HTTP traffic to the web server instances in the private subnets. It performs health checks to ensure traffic is only routed to healthy instances.
- **Security Groups:**
  - **ec2-ssm-instance-sg:** Controls traffic for the EC2 instances. It allows inbound HTTP from the CLB, and all ingress from itself (for inter-instance communication), and necessary egress for SSM and general internet access via NAT Gateway.
  - **ssm-vpc-endpoint-sg:** Controls traffic for the SSM VPC Endpoints, allowing inbound HTTPS only from EC2 instances security group.
  - **elb-sg:** Controls traffic for the CLB, allowing inbound HTTP from the internet and outbound traffic to the EC2 instances security group.


**Features**

- **High Availability:** Web servers distributed across two Availability Zones with load balancing.
- **Secure Remote Management:** SSH is not required; instances are managed via AWS Systems Manager (SSM) Session Manager.
- **Private Subnet Deployment:** EC2 instances reside in private subnets, enhancing security.
- **Automated Web Server Setup:** User data script installs and configures Apache HTTPD on instance launch.
- **Private Connectivity to AWS Services:** VPC Endpoints ensure SSM traffic stays within the AWS network.
