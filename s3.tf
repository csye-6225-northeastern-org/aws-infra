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

  tags = {
    Name = "csye6225-${lower(var.profile)}-private-bucket"
  }
}

# Add a lifecycle policy to transition objects to STANDARD_IA storage class after 30 days
resource "aws_s3_bucket_lifecycle_configuration" "example_lifecycle" {
  rule {
    status = "Enabled"
    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }
    id = "s3-lifecycle-rule"
    filter {
      prefix = ""
    }
  }
  bucket = aws_s3_bucket.private_bucket.id
}

resource "random_id" "random_bucket_name" {
  byte_length = 4
  prefix      = "my-bucket-name-"
}

resource "aws_iam_policy" "webapp_s3_policy" {
  name = "WebAppS3Policy"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Action" : [
          "s3:GetObject",
          "s3:GetObjectAcl",
          "s3:PutObject",
          "s3:PutObjectAcl",
          "s3:DeleteObject",
          "s3:ListBucket"
        ],
        "Effect" : "Allow",
        "Resource" : [
          "arn:aws:s3:::${aws_s3_bucket.private_bucket.bucket}",
          "arn:aws:s3:::${aws_s3_bucket.private_bucket.bucket}/*"
        ]
      }
    ]
    }
  )
}

resource "aws_s3_bucket_server_side_encryption_configuration" "private_bucket" {
  bucket = aws_s3_bucket.private_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
