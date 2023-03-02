resource "aws_s3_bucket" "private_bucket" {
  bucket        = "csye6225-${lower(var.profile)}-${random_id.random_bucket_name.hex}"
  acl           = "private"
  force_destroy = true

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  lifecycle {
    prevent_destroy = false
  }

  # Add a lifecycle policy to transition objects to STANDARD_IA storage class after 30 days
  policy = jsonencode({
    rules = [{
      status = "Enabled"
      transitions = [{
        days          = 30
        storage_class = "STANDARD_IA"
      }]
      filter = {
        prefix = ""
      }
    }]
  })

  tags = {
    Name = "csye6225-${lower(var.profile)}-private-bucket"
  }
}

resource "random_id" "random_bucket_name" {
  byte_length = 4
  prefix      = "my-bucket-name-"
}

resource "aws_iam_policy" "webapp_s3_policy" {
  name = "WebAppS3Policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = ["s3:*"]
        Resource = [
          "arn:aws:s3:::${random_id.random_bucket_name.hex}",
          "arn:aws:s3:::${random_id.random_bucket_name.hex}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "webapp_s3_policy_attachment" {
  policy_arn = aws_iam_policy.webapp_s3_policy.arn
  role       = aws_iam_role.ec2_role.name
}

resource "aws_s3_bucket_server_side_encryption_configuration" "private_bucket" {
  bucket = aws_s3_bucket.private_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}