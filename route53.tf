variable "dev_hostedzone_id" {
  type = string
}
variable "prod_hostedzone_id" {
  type = string
}
variable "dev_A_record_name" {
  type = string
}
variable "prod_A_record_name" {
  type = string
}
resource "aws_eip" "eip" {
  instance = aws_instance.ec2.id
  vpc      = true
}
resource "aws_route53_record" "nithinbharadwaj_A_record" {
  zone_id = var.profile == "dev" ? var.dev_hostedzone_id : var.prod_hostedzone_id
  name    = var.profile == "dev" ? var.dev_A_record_name : var.prod_A_record_name
  type    = "A"
  ttl     = 300
  records = [aws_eip.eip.public_ip]
}
