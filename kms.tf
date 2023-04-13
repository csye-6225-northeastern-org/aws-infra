data "aws_caller_identity" "current" {
}


resource "aws_kms_key" "rds_key" {
  description = "RDS encryption key"
  policy      = data.aws_iam_policy_document.rds_key_policy.json
}

data "aws_iam_policy_document" "rds_key_policy" {
  statement {
    sid    = "Allow administration of the key"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }

    actions   = ["kms:*"]
    resources = ["*"]
  }
}

resource "aws_kms_key" "ebs_key" {
  description = "EBS encryption key"
  policy      = data.aws_iam_policy_document.ebs_key_policy.json
}

data "aws_iam_policy_document" "ebs_key_policy" {
  statement {
    sid    = "Allow administration of the key"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }

    actions   = ["kms:*"]
    resources = ["*"]
  }
}

