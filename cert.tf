data "aws_acm_certificate" "my_cert" {
  domain   = var.profile == "demo" ? var.prod_A_record_name : var.dev_A_record_name
  statuses = ["ISSUED"]
}