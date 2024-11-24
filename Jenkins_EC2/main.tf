# VPC
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "jenkins_vpc"
  cidr = var.vpc_cidr

  azs            = data.aws_availability_zones.azs.names
  public_subnets = var.public_subnets

  enable_dns_hostnames = true
  # When set to true, it enables DNS hostnames for instances launched in the VPC. 
  # This means that instances will receive a public DNS hostname that can be 
  # resolved to their public IP address.
  map_public_ip_on_launch = true
  # When set to true, all instances in the VPC will receive a public IP address
  # if it is launched in a public subnet.

  tags = {
    Name      = "jenkins_vpc"
    Terraform = "true"
  }
}

# Security Group
module "sg" {
  source = "terraform-aws-modules/security-group/aws"

  name        = "jenkins_sg"
  description = "Security group for jenkins server"
  vpc_id      = module.vpc.vpc_id


  ingress_with_cidr_blocks = [
    {
      from_port   = 8080
      to_port     = 8080
      protocol    = "tcp"
      description = "HTTP"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      description = "SSH"
      cidr_blocks = "0.0.0.0/0"
    }
  ]
  egress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = "0.0.0.0/0"
    }
  ]
  tags = {
    Name      = "jenkins_sg"
    Terraform = "true"
  }
}

resource "aws_network_acl" "main" {
  vpc_id = module.vpc.vpc_id

  ingress {
    rule_no    = 100
    action     = "allow"
    protocol   = "tcp"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 65535
  }

  egress {
    rule_no    = 100
    action     = "allow"
    protocol   = "tcp"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 65535
  }

  tags = {
    Name = "network_acl"
  }
}

# EC2 Instance
module "ec2_instance" {
  source = "terraform-aws-modules/ec2-instance/aws"

  name = "jenkins_server"

  instance_type = var.instance_type
  ami           = data.aws_ami.example.id
  key_name      = "jenkins_ssh_key"
  # monitoring                  = true  # Enable detailed monitoring
  vpc_security_group_ids      = [module.sg.security_group_id]
  subnet_id                   = module.vpc.public_subnets[0]
  associate_public_ip_address = true
  availability_zone           = data.aws_availability_zones.azs.names[0]
  user_data                   = file("jenkins-install.sh")


  tags = {
    Name      = "jenkins_server"
    Terraform = "true"
  }
}