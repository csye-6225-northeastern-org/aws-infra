# AWS && Terraform 
This Terraform code creates an AWS VPC (Virtual Private Cloud) along with public and private subnets, an internet gateway, and route tables.

## Variables
The following variables are used in the code:

- profile: AWS profile to be used.
- region: AWS region to be used. 
- vpc_cidr_block: CIDR block for the VPC.
- destination_cidr_block: Destination CIDR block.
- vpc_cidr_block_prefix: Prefix for the VPC CIDR block.
- vpc_cidr_block_postfix: Postfix for the VPC CIDR block.
## Providers
The code uses the aws provider to interact with the AWS services. The provider takes the following input variables:

- region: AWS region to be used.
- profile: AWS profile to be used.
## Resources
The code creates the following AWS resources:

- **aws_vpc**: Creates the AWS VPC with the specified CIDR block and tags.
- **data.aws_availability_zones**: Gets the available zones in the current region.
- **aws_subnet.public_subnet**: Creates public subnets in the VPC using the available zones.
- **aws_subnet.private_subnet**: Creates private subnets in the VPC using the available zones.
- **aws_internet_gateway**: Creates an internet gateway for the VPC.
- **aws_route_table.public_route_table**: Creates a public route table for the VPC with the specified CIDR block and gateway.
- **aws_route_table_association.public_subnet_association**: Associates the public subnets with the public route table.
- **aws_route_table.private_route_table**: Creates a private route table for the VPC.
- **aws_route_table_association.private_subnet_association**: Associates the private subnets with the private route table.
The code uses the locals block to get the top 3 available zones, if available.

## Usage
To use the code, the following steps can be followed:

- Create a file with a .tf extension and paste the code.
- Configure the input variables in the file.
- Run the `terraform init` command to initialize the working directory.
- Run the `terraform plan` command to get the blueprint of the resources being created.
- Run the `terraform apply` command to apply the changes and create the resources in the AWS account.
  