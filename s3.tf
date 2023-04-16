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

  # lifecycle {
  #   prevent_destroy = false
  # }

  tags = {
    Name = "csye6225-${lower(var.profile)}-private-bucket"
  }
}

# Add a lifecycle policy to transition objects to STANDARD_IA storage class after 30 days
resource "aws_s3_bucket_lifecycle_configuration" "example_lifecycle" {
  bucket = aws_s3_bucket.private_bucket.id
  rule {
    id = "log"
    expiration {
      days = 90
    }
    filter {
      and {
        prefix = "log/"
        tags = {
          rule      = "log"
          autoclean = "true"
        }
      }
    }

    status = "Enabled"
    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }
  }
}

resource "random_id" "random_bucket_name" {
  byte_length = 4
  prefix      = "my-bucket-name-"
}

resource "aws_iam_policy" "webapp_s3_policy" {
  name        = "WebAppS3"
  path        = "/"
  description = "My s3 IAM policy"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:ListAllMyBuckets",
          "s3:ListBucket",
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:PutObjectAcl",
          "s3:ListMultipartUploadParts",
          "s3:AbortMultipartUpload",
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ]
        Effect = "Allow"
        Resource = [
          "arn:aws:s3:::${aws_s3_bucket.private_bucket.bucket}",
          "arn:aws:s3:::${aws_s3_bucket.private_bucket.bucket}/*"
        ]
      },
    ]
  })
}

# resource "aws_s3_bucket_server_side_encryption_configuration" "private_bucket" {
#   bucket = aws_s3_bucket.private_bucket.id

#   rule {
#     apply_server_side_encryption_by_default {
#       sse_algorithm = "AES256"
#     }
#   }
# }
