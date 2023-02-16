variable "profile" {
  type    = string
  default = null
}

variable "region" {
  type    = string
  default = null
}

variable "vpc_cidr_block" {}
variable "destination_cidr_block" {}

provider "aws" {
  region  = var.region
  profile = var.profile
}

resource "aws_vpc" "a3_vpc" {
  cidr_block = var.vpc_cidr_block
  tags = {
    Name = "Automated"
  }
}

# Gets the available zones in the current region
data "aws_availability_zones" "available" {
  state = "available"
}

# Gets the top 3 availability zones
locals {
  az_slice = length(data.aws_availability_zones.available.names) > 2 ? slice(data.aws_availability_zones.available.names, 0, 3) : data.aws_availability_zones.available.names
}

# Creating public subnets
resource "aws_subnet" "public_subnet" {
  count = length(local.az_slice)

  cidr_block        = "10.0.${count.index + 1}.0/24"
  vpc_id            = aws_vpc.a3_vpc.id
  availability_zone = element(local.az_slice, count.index)

  map_public_ip_on_launch = true

  tags = {
    Name = "public_subnet_${count.index + 1}"
  }
}

resource "aws_subnet" "private_subnet" {
  count = length(local.az_slice)

  cidr_block        = "10.0.${count.index + 11}.0/24"
  vpc_id            = aws_vpc.a3_vpc.id
  availability_zone = element(local.az_slice, count.index)

  map_public_ip_on_launch = false

  tags = {
    Name = "private_subnet_${count.index + 1}"
  }
}

# Creating internet gateway
resource "aws_internet_gateway" "a3_igw" {
  vpc_id = aws_vpc.a3_vpc.id

  tags = {
    Name = "a3_igw"
  }
}


# Creating public route table 
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.a3_vpc.id

  route {
    cidr_block = var.destination_cidr_block
    gateway_id = aws_internet_gateway.a3_igw.id
  }

  tags = {
    Name = "public_route_table"
  }
}

resource "aws_route_table_association" "public_subnet_association" {
  count = length(aws_subnet.public_subnet)

  subnet_id      = aws_subnet.public_subnet[count.index].id
  route_table_id = aws_route_table.public_route_table.id
}


# Creating private route table
resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.a3_vpc.id

  tags = {
    Name = "private_route_table"
  }
}

resource "aws_route_table_association" "private_subnet_association" {
  count = length(aws_subnet.private_subnet)

  subnet_id      = aws_subnet.private_subnet[count.index].id
  route_table_id = aws_route_table.private_route_table.id
}
