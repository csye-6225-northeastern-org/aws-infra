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
  # depends_on = [
  #   aws_iam_policy.webapp_s3_policy, aws_iam_policy.WebAppCloudWatch
  # ]

  tags = {
    Name = "EC2-CSYE6225"
  }
}

resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "EC2-CSYE6225-Instance-Profile"
  role = aws_iam_role.ec2_role.name
}

# Create IAM policy for Cloudwatch
data "aws_iam_policy" "WebAppCloudWatch" {
  arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_role_policy_attachment" "cloudwatch_agent_policy_attachment" {
  policy_arn = data.aws_iam_policy.WebAppCloudWatch.arn
  role       = aws_iam_role.ec2_role.name
}

resource "aws_iam_role_policy_attachment" "webapp_s3_policy_attachment" {
  policy_arn = aws_iam_policy.webapp_s3_policy.arn
  role       = aws_iam_role.ec2_role.name
}

resource "aws_iam_policy_attachment" "webapp_s3_policy_attachment" {
  name       = "ec2-s3-iam-role-policy"
  roles      = [aws_iam_role.ec2_role.name]
  policy_arn = aws_iam_policy.webapp_s3_policy.arn
}

# resource "aws_iam_policy_attachment" "cloudwatch_agent_policy_attachment" {
#   name       = "ec2-cloudwatch-iam-role-policy"
#   roles      = [aws_iam_role.ec2_role.name]
#   policy_arn = data.aws_iam_policy.WebAppCloudWatch.arn
# }
