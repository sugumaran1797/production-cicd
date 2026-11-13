terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "ap-south-1"
}

# Fetch the latest Ubuntu 22.04 LTS AMI in ap-south-1
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

# Upload your local public key to AWS
resource "aws_key_pair" "devops_key" {
  key_name   = "devops-ec2-key"
  public_key = file("~/.ssh/devops-ec2-key.pub")
}

# Firewall rules for SSH, HTTP, Flask App, and Prometheus
resource "aws_security_group" "devops_sg" {
  name        = "devops-cicd-sg"
  description = "Allow SSH, HTTP, Flask, and Prometheus traffic"

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Flask App"
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Prometheus"
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Provision the EC2 instance
resource "aws_instance" "devops_server" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.micro"
  key_name               = aws_key_pair.devops_key.key_name
  vpc_security_group_ids = [aws_security_group.devops_sg.id]

  tags = {
    Name = "devops-production-cicd-server"
  }
}

output "ec2_public_ip" {
  description = "Public IP of the EC2 instance"
  value       = aws_instance.devops_server.public_ip
}
