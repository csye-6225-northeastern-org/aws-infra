# Create IAM role for EC2
resource "aws_iam_role" "ec2_role" {
  name = "EC2-CSYE6225"
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

  # Attach WebAppS3 policy to EC2 role
  depends_on = [
    aws_iam_policy.webapp_s3_policy
  ]

  tags = {
    Name = "EC2-CSYE6225"
  }
}

resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "EC2-CSYE6225-Instance-Profile"

  role = aws_iam_role.ec2_role.name
}