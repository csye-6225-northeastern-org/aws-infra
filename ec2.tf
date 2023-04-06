
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

variable "volume_type" {
  type    = string
  default = "gp2"
}

variable "volume_size" {
  default = 50
}

variable "NODE_ENV" {
  type    = string
  default = "development"
}

variable "PORT" {
  default = 3000
}

variable "DIALECT" {
  type    = string
  default = "postgresql"
}

variable "default_cidr_block" {
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
  depends_on  = [aws_security_group.load_balancer]

  # Add ingress rules to allow traffic on ports 22, 80, 443, and 3081
  # ingress {
  #   from_port   = 22
  #   to_port     = 22
  #   protocol    = "tcp"
  #   cidr_blocks = [var.destination_cidr_block]
  # }

  # ingress {
  #   from_port   = 80
  #   to_port     = 80
  #   protocol    = "tcp"
  #   cidr_blocks = [var.destination_cidr_block]
  # }

  # ingress {
  #   from_port   = 443
  #   to_port     = 443
  #   protocol    = "tcp"
  #   cidr_blocks = [var.destination_cidr_block]
  # }

  ingress {
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    security_groups = [aws_security_group.load_balancer.id]
    cidr_blocks     = [var.destination_cidr_block]
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
  depends_on    = [aws_db_instance.rds_instance, aws_s3_bucket.private_bucket]
  ami           = data.aws_ami.webapp_ami.id
  instance_type = var.ec2_class
  key_name      = var.key_pair
  subnet_id     = aws_subnet.public_subnet[0].id

  user_data = local.user_data
  #Sending User Data to EC2
  #   user_data = <<EOT
  # #!/bin/bash
  # cat <<EOF > /etc/systemd/system/webapp.service
  # [Unit]
  # Description=Webapp Service
  # After=network.target

  # [Service]
  # Environment="NODE_ENV=${var.NODE_ENV}"
  # Environment="PORT=${var.PORT}"
  # Environment="DIALECT=${var.DIALECT}"
  # Environment="HOST=${element(split(":", aws_db_instance.rds_instance.endpoint), 0)}"
  # Environment="USERNAME=${aws_db_instance.rds_instance.username}"
  # Environment="PASSWORD=${aws_db_instance.rds_instance.password}"
  # Environment="DB_NAME=${aws_db_instance.rds_instance.db_name}"
  # Environment="S3_BUCKET_NAME=${aws_s3_bucket.private_bucket.bucket}"
  # Environment="REGION=${var.region}"

  # Type=simple
  # User=ec2-user
  # WorkingDirectory=/home/ec2-user/webapp
  # ExecStart=/usr/bin/node server.js
  # Restart=on-failure
  # SyslogIdentifier=webapp

  # [Install]
  # WantedBy=multi-user.target" > /etc/systemd/system/webapp.service
  # EOF

  # sudo systemctl daemon-reload
  # sudo systemctl start webapp.service
  # sudo systemctl enable webapp.service
  # sudo systemctl status webapp.service
  # journalctl -u webapp.service

  # # Setting up ngnix for reverse-proxy
  # sudo yum update -y
  # sudo amazon-linux-extras install nginx1 -y

  # ENVIRONMENT=${var.profile}
  # if [ "$ENVIRONMENT" == "dev" ]; then
  #   server_name="${var.dev_A_record_name}"
  # else
  #   server_name="${var.prod_A_record_name}"
  # fi

  # cat <<EOF > /etc/nginx/conf.d/reverse-proxy.conf
  # server { 
  #   listen 80; 
  #   server_name $server_name; 
  #   location / { 
  #     proxy_pass http://localhost:3000;
  #   }
  # }
  # EOF
  # sudo systemctl reload nginx
  # sudo systemctl start nginx
  # sudo systemctl enable nginx

  # # Configure CloudWatch agent
  # sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -s -c file:/tmp/config.json

  # EOT

  vpc_security_group_ids = ["${aws_security_group.app_security_group.id}"]
  root_block_device {
    volume_type           = var.volume_type
    volume_size           = var.volume_size
    delete_on_termination = true
  }
  disable_api_termination = false

  # Attach EC2 role to instance
  iam_instance_profile = aws_iam_instance_profile.ec2_instance_profile.name

}


locals {
  user_data = templatefile("${path.module}/user_data.tpl", {
    NODE_ENV           = var.NODE_ENV
    PORT               = var.PORT
    DIALECT            = var.DIALECT
    rds_host           = element(split(":", aws_db_instance.rds_instance.endpoint), 0)
    rds_username       = aws_db_instance.rds_instance.username
    rds_password       = aws_db_instance.rds_instance.password
    rds_db_name        = aws_db_instance.rds_instance.db_name
    s3_bucket_name     = aws_s3_bucket.private_bucket.bucket
    region             = var.region
    profile            = var.profile
    dev_A_record_name  = var.dev_A_record_name
    prod_A_record_name = var.prod_A_record_name
  })
}

# Outputting if the RDS username and host that were created 
output "RDS_USERNAME" {
  value = "${aws_instance.ec2.public_ip}:${aws_db_instance.rds_instance.username}"
}

output "HOST" {
  value = "${aws_instance.ec2.public_ip}:${element(split(":", aws_db_instance.rds_instance.endpoint), 0)}"
}

