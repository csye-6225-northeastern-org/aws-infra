resource "aws_launch_template" "asg_launch_template" {
  name          = "webapp-launch-template"
  image_id      = data.aws_ami.webapp_ami.id
  instance_type = var.ec2_class
  key_name      = var.key_pair
  user_data     = base64encode(local.user_data)
  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_instance_profile.name
  }
  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.app_security_group.id]
  }
  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "webapp-instance"
    }
  }

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size           = 50
      volume_type           = "gp2"
      delete_on_termination = true
      # encrypted             = true
      # kms_key_id            = aws_kms_key.ebs_key.arn
    }
  }

}

resource "aws_autoscaling_group" "asg" {
  name = "web_app_asg"
  # launch_configuration = aws_launch_configuration.asg_launch_config.id
  launch_template {
    id      = aws_launch_template.asg_launch_template.id
    version = "$Latest"
  }
  min_size         = 1
  max_size         = 3
  desired_capacity = 1

  vpc_zone_identifier = [for subnet in aws_subnet.private_subnet : subnet.id]
  health_check_type   = "EC2"

  default_cooldown  = 60
  target_group_arns = [aws_lb_target_group.load_balancer_target_group.arn]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_policy" "scale_up" {
  name                    = "scale-up"
  autoscaling_group_name  = aws_autoscaling_group.asg.name
  adjustment_type         = "ChangeInCapacity"
  scaling_adjustment      = 1
  cooldown                = 60
  policy_type             = "SimpleScaling"
  metric_aggregation_type = "Average"
}

resource "aws_autoscaling_policy" "scale_down" {
  name                    = "scale-down"
  autoscaling_group_name  = aws_autoscaling_group.asg.name
  adjustment_type         = "ChangeInCapacity"
  scaling_adjustment      = -1
  cooldown                = 60
  policy_type             = "SimpleScaling"
  metric_aggregation_type = "Average"
}

resource "aws_cloudwatch_metric_alarm" "scale_up_alarm" {
  alarm_name          = "scale-up-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "30"
  statistic           = "Average"
  threshold           = "5"
  alarm_description   = "This metric checks if the CPU usage is above 5%"
  alarm_actions       = ["${aws_autoscaling_policy.scale_up.arn}"]
  actions_enabled     = true
  dimensions = {
    "AutoScalingGroupName" = "${aws_autoscaling_group.asg.name}"
  }
}

resource "aws_cloudwatch_metric_alarm" "scale_down_alarm" {
  alarm_name          = "scale-down-alarm"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "60"
  statistic           = "SampleCount"
  threshold           = "3"
  alarm_description   = "This metric checks if the CPU usage is below 3%"
  alarm_actions       = ["${aws_autoscaling_policy.scale_down.arn}"]
  actions_enabled     = true
  dimensions = {
    AutoScalingGroupName = "${aws_autoscaling_group.asg.name}"
  }
}

# resource "aws_autoscaling_attachment" "webapp_asg_attachment" {
#   autoscaling_group_name = aws_autoscaling_group.webapp_asg.id
#   alb_target_group_arn   = aws_lb_target_group.load_balancer_target_group.arn
# }

