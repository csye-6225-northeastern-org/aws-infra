resource "aws_security_group" "load_balancer" {
  name        = "load_balancer_security_group"
  description = "Security group for load balancer to access the web application"
  vpc_id      = aws_vpc.a3_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.destination_cidr_block]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.destination_cidr_block]
  }

  egress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = [var.destination_cidr_block]
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "load-balancer-security-gp"
  }
}


resource "aws_lb" "webapp_load_balancer" {
  name               = "webapp-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.load_balancer.id]
  subnets            = [for subnet in aws_subnet.public_subnet : subnet.id]
}

resource "aws_lb_listener" "load_balancer_listener" {
  load_balancer_arn = aws_lb.webapp_load_balancer.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.load_balancer_target_group.arn
  }
}

resource "aws_lb_target_group" "load_balancer_target_group" {
  name     = "load-balancer-target-group"
  port     = 3000
  protocol = "HTTP"
  vpc_id   = aws_vpc.a3_vpc.id
  health_check {
    path                = "/healthz"
    protocol            = "HTTP"
    interval            = 30
    timeout             = 10
    healthy_threshold   = 3
    unhealthy_threshold = 3
    matcher             = "200"
  }
}

# resource "aws_lb_target_group_attachment" "load_balancer_group_attachment" {
#   target_group_arn = aws_lb_target_group.load_balancer_target_group.arn
#   target_id        = aws_instance.ec2.id
#   port             = 3000
# }
