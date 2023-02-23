
variable "ec2_class" {
  type    = string
  default = null
}

variable "key_pair" {
  type    = string
  default = null
}

variable "ami_owner" {
  type = string
}

variable "ami_pattern" {
  type = string
}

data "aws_ami" "webapp_ami" {
  most_recent = true

  filter {
    name   = "name"
    values = [var.ami_pattern]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = [var.ami_owner]
}

resource "aws_security_group" "app_security_group" {
  name_prefix = "app-security-group"
  description = "Security group for EC2 instances hosting web applications."
  vpc_id      = aws_vpc.a3_vpc.id

  # Add ingress rules to allow traffic on ports 22, 80, 443, and 3081
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.destination_cidr_block]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.destination_cidr_block]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.destination_cidr_block]
  }

  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = [var.destination_cidr_block]
  }

  # Add egress rule to allow all traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.destination_cidr_block]
  }

  # Reference the security group in other resources using the ID
  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "app-security-group"
  }
}



resource "aws_instance" "ec2" {
  ami                    = data.aws_ami.webapp_ami.id
  instance_type          = var.ec2_class
  key_name               = var.key_pair
  subnet_id              = aws_subnet.public_subnet[0].id
  vpc_security_group_ids = ["${aws_security_group.app_security_group.id}"]
  root_block_device {
    volume_type           = "gp2"
    volume_size           = 50
    delete_on_termination = true
  }
  disable_api_termination = false
}

