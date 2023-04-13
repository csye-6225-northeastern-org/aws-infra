resource "aws_launch_template" "asg_launch_template" {
  name                    = "webapp-launch-template"
  image_id                = data.aws_ami.webapp_ami.id
  instance_type           = var.ec2_class
  key_name                = var.key_pair
  disable_api_termination = false
  ebs_optimized           = false

  user_data = base64encode(local.user_data)
  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_instance_profile.name
  }
  network_interfaces {
    associate_public_ip_address = true
    subnet_id                   = aws_subnet.public_subnet[0].id
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
  target_group_arns   = [aws_lb_target_group.load_balancer_target_group.arn]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_policy" "scale_up_policy" {
  name                    = "scale_up_policy"
  policy_type             = "SimpleScaling"
  adjustment_type         = "ChangeInCapacity"
  autoscaling_group_name  = aws_autoscaling_group.asg.name
  scaling_adjustment      = 1
  cooldown                = 60
  metric_aggregation_type = "Average"
}


resource "aws_autoscaling_policy" "scale_down_policy" {
  name                    = "scale_down_policy"
  policy_type             = "SimpleScaling"
  adjustment_type         = "ChangeInCapacity"
  autoscaling_group_name  = aws_autoscaling_group.asg.name
  scaling_adjustment      = -1
  cooldown                = 60
  metric_aggregation_type = "Average"
}

resource "aws_cloudwatch_metric_alarm" "scale_up_alarm" {
  alarm_name          = "scale_up_alarm"
  alarm_description   = "scaleupalarm"
  evaluation_periods  = "1"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "60"
  statistic           = "Average"
  threshold           = "5"
  alarm_actions       = ["${aws_autoscaling_policy.scale_up_policy.arn}"]
  actions_enabled     = true
  dimensions = {
    "AutoScalingGroupName" = "${aws_autoscaling_group.asg.name}"
  }
}

resource "aws_cloudwatch_metric_alarm" "scale_down_alarm" {
  alarm_name          = "scale_down_alarm"
  alarm_description   = "scaledownalarm"
  evaluation_periods  = "1"
  comparison_operator = "LessThanOrEqualToThreshold"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "60"
  statistic           = "Average"
  threshold           = "3"
  alarm_actions       = ["${aws_autoscaling_policy.scale_down_policy.arn}"]
  actions_enabled     = true
  dimensions = {
    AutoScalingGroupName = "${aws_autoscaling_group.asg.name}"
  }
}

