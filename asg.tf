resource "aws_launch_template" "lt" {
  name_prefix            = "webapp-lt-"
  image_id               = data.aws_ami.webapp_ami.id
  instance_type          = var.ec2_class
  key_name               = var.key_pair
  user_data              = base64encode(local.user_data)
  vpc_security_group_ids = [aws_security_group.app_security_group.id]

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_instance_profile.name
  }
  # network_interfaces {
  #   associate_public_ip_address = true
  #   security_groups             = [aws_security_group.app_security_group.id]
  # }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "asg" {
  launch_template {
    id      = aws_launch_template.lt.id
    version = aws_launch_template.lt.latest_version
  }

  min_size         = 1
  max_size         = 3
  desired_capacity = 1

  vpc_zone_identifier = [for subnet in aws_subnet.public_subnet : subnet.id]

  default_cooldown = 60
  tags = [
    {
      key                 = "csye6225"
      value               = "webapp-asg-instance"
      propagate_at_launch = true
    }
  ]
}

resource "aws_appautoscaling_target" "asg_target" {
  max_capacity       = 3
  min_capacity       = 1
  resource_id        = "autoScalingGroupName/${aws_autoscaling_group.asg.name}"
  scalable_dimension = "autoscaling:autoScalingGroup:DesiredCapacity"
  service_namespace  = "autoscaling"
}


resource "aws_appautoscaling_policy" "scale_up_policy" {
  name               = "scale-up"
  policy_type        = "StepScaling"
  resource_id        = aws_appautoscaling_target.asg_target.resource_id
  scalable_dimension = aws_appautoscaling_target.asg_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.asg_target.service_namespace

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 60
    metric_aggregation_type = "Average"

    step_adjustment {
      scaling_adjustment          = 1
      metric_interval_lower_bound = 0.0
      metric_interval_upper_bound = 5.0
    }
  }
}

resource "aws_appautoscaling_policy" "scale_down_policy" {
  name               = "scale-down"
  policy_type        = "StepScaling"
  resource_id        = aws_appautoscaling_target.asg_target.resource_id
  scalable_dimension = aws_appautoscaling_target.asg_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.asg_target.service_namespace

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 60
    metric_aggregation_type = "Average"

    step_adjustment {
      scaling_adjustment          = -1
      metric_interval_lower_bound = 3.0
      metric_interval_upper_bound = 0.0
    }
  }
}

# # Launch Configuration
# resource "aws_launch_configuration" "asg_launch_config" {
#   name_prefix                 = "asg_launch_config"
#   image_id                    = data.aws_ami.webapp_ami.id
#   instance_type               = "t2.micro"
#   associate_public_ip_address = true
#   user_data                   = local.user_data
#   security_groups             = [aws_security_group.app_security_group.id]
#   iam_instance_profile        = "csye6225-webapp"

#   lifecycle {
#     create_before_destroy = true
#   }
# }

# # Auto Scaling Group
# resource "aws_autoscaling_group" "webapp_asg" {
#   launch_configuration = aws_launch_configuration.asg_launch_config.id
#   min_size             = 1
#   max_size             = 3
#   desired_capacity     = 1
#   cooldown             = 60
#   vpc_zone_identifier  = [for subnet in aws_subnet.public_subnet : subnet.id]

#   tag {
#     key                 = "Name"
#     value               = "webapp-instance"
#     propagate_at_launch = true
#   }
# }

# # AutoScaling Policies
# resource "aws_autoscaling_policy" "scale_up" {
#   name                   = "scale_up"
#   scaling_adjustment     = 1
#   adjustment_type        = "ChangeInCapacity"
#   cooldown               = 60
#   autoscaling_group_name = aws_autoscaling_group.webapp_asg.id

#   alarm_settings {
#     alarm_name          = "scale_up_alarm"
#     comparison_operator = "GreaterThanOrEqualToThreshold"
#     evaluation_periods  = "1"
#     metric_name         = "CPUUtilization"
#     namespace           = "AWS/EC2"
#     period              = "60"
#     statistic           = "SampleCount"
#     threshold           = "5"
#   }
# }


# resource "aws_autoscaling_policy" "scale_down" {
#   name                   = "scale_down"
#   scaling_adjustment     = -1
#   adjustment_type        = "ChangeInCapacity"
#   cooldown               = 60
#   autoscaling_group_name = aws_autoscaling_group.webapp_asg.id

#   alarm_settings {
#     alarm_name          = "scale_down_alarm"
#     comparison_operator = "LessThanOrEqualToThreshold"
#     evaluation_periods  = "1"
#     metric_name         = "CPUUtilization"
#     namespace           = "AWS/EC2"
#     period              = "60"
#     statistic           = "SampleCount"
#     threshold           = "3"
#   }
# }

# resource "aws_autoscaling_attachment" "webapp_asg_attachment" {
#   autoscaling_group_name = aws_autoscaling_group.webapp_asg.id
#   alb_target_group_arn   = aws_lb_target_group.load_balancer_target_group.arn
# }

