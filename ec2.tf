
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

variable "db_username" {
  type    = string
  default = "csye6225"
}

variable "db_password" {
  type    = string
  default = "postgres"
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



# resource "aws_instance" "ec2" {
#   ami                    = data.aws_ami.webapp_ami.id
#   instance_type          = var.ec2_class
#   key_name               = var.key_pair
#   subnet_id              = aws_subnet.public_subnet[0].id
#   vpc_security_group_ids = ["${aws_security_group.app_security_group.id}"]
#   root_block_device {
#     volume_type           = "gp2"
#     volume_size           = 50
#     delete_on_termination = true
#   }
#   disable_api_termination = false
# }


resource "aws_instance" "ec2" {
  depends_on    = [aws_db_instance.rds_instance, aws_s3_bucket.private_bucket]
  ami           = data.aws_ami.webapp_ami.id
  instance_type = var.ec2_class
  key_name      = var.key_pair
  subnet_id     = aws_subnet.public_subnet[0].id

  #Sending User Data to EC2
  user_data = <<EOT
#!/bin/bash
cat <<EOF > /etc/systemd/system/webapp.service
[Unit]
Description=Webapp Service
After=network.target

[Service]
Environment="NODE_ENV=development"
Environment="PORT=3000"
Environment="DIALECT=postgresql"
Environment="DB_HOST=${element(split(":", aws_db_instance.rds_instance.endpoint), 0)}"
Environment="DB_USERNAME=${aws_db_instance.rds_instance.username}"
Environment="DB_PASSWORD=${aws_db_instance.rds_instance.password}"
Environment="DB_NAME=${aws_db_instance.rds_instance.db_name}"
Environment="S3_BUCKET_NAME=${aws_s3_bucket.private_bucket.bucket}"
Environment="AWS_REGION=${var.region}"

Type=simple
User=ec2-user
WorkingDirectory=/home/ec2-user/webapp
ExecStart=/usr/bin/node server-listener.js
Restart=on-failure

[Install]
WantedBy=multi-user.target" > /etc/systemd/system/webapp.service
EOF

sudo systemctl daemon-reload
sudo systemctl start webapp.service
sudo systemctl enable webapp.service

echo 'export NODE_ENV=dev' >> /home/ec2-user/.bashrc,
echo 'export PORT=3000' >> /home/ec2-user/.bashrc,
echo 'export DIALECT=mysql' >> /home/ec2-user/.bashrc,
echo 'export DB_HOST=${element(split(":", aws_db_instance.rds_instance.endpoint), 0)}' >> /home/ec2-user/.bashrc,
echo 'export DB_USERNAME=${aws_db_instance.rds_instance.username}' >> /home/ec2-user/.bashrc,
echo 'export DB_PASSWORD=${aws_db_instance.rds_instance.password}' >> /home/ec2-user/.bashrc,
echo 'export DB_NAME=${aws_db_instance.rds_instance.db_name}' >> /home/ec2-user/.bashrc,
echo 'export S3_BUCKET_NAME=${aws_s3_bucket.private_bucket.bucket}' >> /home/ec2-user/.bashrc,
echo 'export AWS_REGION=${var.region}' >> /home/ec2-user/.bashrc,
source /home/ec2-user/.bashrc
EOT

  vpc_security_group_ids = ["${aws_security_group.app_security_group.id}"]
  root_block_device {
    volume_type           = "gp2"
    volume_size           = 50
    delete_on_termination = true
  }
  disable_api_termination = false

  # Attach EC2 role to instance
  iam_instance_profile = aws_iam_instance_profile.ec2_instance_profile.name

}
