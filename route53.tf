variable "dev_hostedzone_id" {
  type    = string
  default = "Z007198424U4DQHRHINXP"
}
variable "prod_hostedzone_id" {
  type    = string
  default = "Z097914418ULQHGLVWJ7H"
}
variable "dev_A_record_name" {
  type    = string
  default = "dev.nithinbharadwaj.me"
}
variable "prod_A_record_name" {
  type    = string
  default = "prod.nithinbharadwaj.me"
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