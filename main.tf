terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

data "aws_caller_identity" "current" {}

provider "aws" {
  region = "${var.aws_region}"
}

resource "aws_vpc" "vpc_1" {
  cidr_block = "172.31.0.0/16"
}

resource "aws_internet_gateway" "internet_gateway_1" {
  vpc_id = aws_vpc.vpc_1.id

  # tags = {
  #   Name = ""
  # }
}

resource "aws_subnet" "subnet_1" {
  vpc_id                  = aws_vpc.vpc_1.id
  cidr_block              = "172.31.0.0/20"
  availability_zone       = "${var.aws_availability_zone}" # Change this to your desired availability zone
  map_public_ip_on_launch = true
}

resource "aws_security_group" "hub_security_group" {
  name        = "launch-wizard"
  description = "launch-wizard created 2023-04-14T20:55:05.027Z"
  vpc_id      = aws_vpc.vpc_1.id

  egress = [
    {
      cidr_blocks      = [
          "0.0.0.0/0",
      ]
      from_port        = 2282
      to_port          = 2283
      protocol         = "tcp"
      description      = ""
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = []
      self             = false
    },
    {
      cidr_blocks      = [
          "0.0.0.0/0",
      ]
      from_port        = 80
      to_port          = 80
      protocol         = "tcp"
      description      = ""
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = []
      self             = false
    },
    {
      cidr_blocks      = [
          "0.0.0.0/0",
      ]
      from_port        = 443
      to_port          = 443
      protocol         = "tcp"
      description      = ""
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = []
      self             = false
    },
  ]

  ingress = [
    {
      cidr_blocks      = [
          "0.0.0.0/0",
      ]
      from_port        = 2282
      to_port          = 2283
      protocol         = "tcp"
      self             = false
      description      = ""
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = []
      self             = false
    },
    {
      cidr_blocks      = [
          "0.0.0.0/0",
      ]
      from_port        = 22
      to_port          = 22
      protocol         = "tcp"
      self             = false
      description      = ""
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = []
      self             = false
    },
  ]

  tags = {
    Name = "hub_security_group"
  }
}

resource "aws_eip" "hubble_eip" {
  vpc = true
}

# Create an IAM role for EC2 instances with the necessary permissions to access ECR
resource "aws_iam_role" "ec2_instance_role" {
  name = "ec2_instance_role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# Attach an IAM policy to the role that allows access to ECR repositories
resource "aws_iam_role_policy_attachment" "ecr_access_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.ec2_instance_role.name
}

# Create an EC2 instance profile and attach the IAM role to it
resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "ec2_instance_profile"
  role = aws_iam_role.ec2_instance_role.name
}

resource "aws_instance" "hub_instance" {
  ami           = "${var.aws_ec2_ami_id}" # This is the Ubuntu Server 22.04 LTS 64-bit (x86) AMI ID
  availability_zone = "${var.aws_availability_zone}"
  instance_type = "m5.large"
  associate_public_ip_address = false

  vpc_security_group_ids = [aws_security_group.hub_security_group.id]
  subnet_id = aws_subnet.subnet_1.id

  iam_instance_profile = aws_iam_instance_profile.ec2_instance_profile.name

  key_name = "${var.key_name}"

  user_data = <<-EOF
              #!/bin/bash
              sudo apt-get update
              sudo apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release
              curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
              echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
              sudo apt-get update
              sudo apt-get install -y docker-ce docker-ce-cli containerd.io
              sudo systemctl start docker
              sudo apt-get install awscli -y
              aws ecr get-login-password --region ${var.aws_region} | sudo docker login --username AWS --password-stdin ${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com
              sudo docker pull ${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/hubble:latest # Replace with the name of your Docker image
              sudo docker run -p 2282:2282 -p 2283:2283 -d ${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/hubble:latest # Add any additional flags or options you need for your container
              EOF

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  tags = {
    Name = "FC Hub"
  }
}

resource "aws_eip_association" "hubble_eip_association" {
  instance_id   = aws_instance.hub_instance.id
  public_ip     = aws_eip.hubble_eip.public_ip
}
