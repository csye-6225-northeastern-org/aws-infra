
# Create a DB security group
resource "aws_security_group" "db_security_group" {
  name_prefix = "db-security-group"
  description = "Security group for RDS instances."
  vpc_id      = aws_vpc.a3_vpc.id

  # Add ingress rule to allow traffic on port 3306/5432 from the app security group
  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.app_security_group.id]
  }

  # Restrict access to the instance from the internet
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Reference the security group in other resources using the ID
  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "db-security-group"
  }
}

resource "aws_db_parameter_group" "db_parameter_group" {
  name_prefix = "db-parameter-group"
  family      = "postgres14"
  description = "Parameter group for CSYE6225"

  parameter {
    apply_method = "pending-reboot"
    name         = "max_connections"
    value        = "100"
  }

  parameter {
    apply_method = "pending-reboot"
    name         = "shared_buffers"
    value        = "16"
  }
}

resource "aws_db_subnet_group" "private_db_subnet_group" {
  name        = "private-db-subnet-group"
  subnet_ids  = aws_subnet.private_subnet.*.id
  description = "Subnet group for private RDS instances"
}

resource "aws_db_instance" "rds_instance" {
  allocated_storage    = 10
  engine               = "postgres"
  engine_version       = "14"
  instance_class       = "db.t3.micro"
  identifier           = "csye6225"
  db_name              = "csye6225"
  username             = "csye6225"
  password             = "postgres"
  parameter_group_name = aws_db_parameter_group.db_parameter_group.name
  publicly_accessible  = false
  skip_final_snapshot  = true

  # Attach database security group to the instance
  vpc_security_group_ids = [aws_security_group.db_security_group.id]

  # Use private subnet group for RDS instances
  db_subnet_group_name = aws_db_subnet_group.private_db_subnet_group.name
}


