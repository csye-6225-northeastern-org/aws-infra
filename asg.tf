resource "aws_launch_configuration" "asg_launch_config" {
  name_prefix                 = "webapp-asg-"
  image_id                    = data.aws_ami.webapp_ami.id
  instance_type               = var.ec2_class
  key_name                    = var.key_pair
  user_data                   = base64encode(local.user_data)
  security_groups             = [aws_security_group.app_security_group.id]
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.ec2_instance_profile.name

  lifecycle {
    create_before_destroy = true
  }

  root_block_device {
    volume_size           = 50
    volume_type           = "gp2"
    delete_on_termination = true
  }
}

resource "aws_autoscaling_group" "asg" {
  name                 = "web_app_asg"
  launch_configuration = aws_launch_configuration.asg_launch_config.id

  min_size         = 1
  max_size         = 3
  desired_capacity = 1

  vpc_zone_identifier = [for subnet in aws_subnet.private_subnet : subnet.id]

  default_cooldown  = 60
  target_group_arns = [aws_lb_target_group.load_balancer_target_group.arn]
  tags = [
    {
      key                 = "csye6225"
      value               = "webapp-asg-instance"
      propagate_at_launch = true
    }
  ]
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
  alarm_actions       = [aws_autoscaling_policy.scale_up.arn]
  actions_enabled     = true
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.asg.name
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
  alarm_actions       = [aws_autoscaling_policy.scale_down.arn]
  actions_enabled     = true
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.asg.name
  }
}

# resource "aws_autoscaling_attachment" "webapp_asg_attachment" {
#   autoscaling_group_name = aws_autoscaling_group.webapp_asg.id
#   alb_target_group_arn   = aws_lb_target_group.load_balancer_target_group.arn
# }

