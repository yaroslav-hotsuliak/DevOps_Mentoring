provider "aws" {
  profile = "default"
  region  = "us-east-1"
}

resource "aws_security_group" "my_security_group" {
  name        = "tf-security-group"
  description = "ASG security group"

  ingress {
    description      = "allow http"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }
  ingress {
    description      = "allow ssh"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }  
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }
}

resource "aws_lb" "my_lb" {
  name               = "tf-load-balancer"
  load_balancer_type = "application"
  security_groups    = [aws_security_group.my_security_group.id]
  subnets            = ["subnet-95b42cb4", "subnet-2fc05e70"]
}

resource "aws_launch_template" "my_launch_template" {
  name_prefix   = "tf-launch-template"
  image_id      = "ami-0c5758a904e4ba6e2"
  instance_type = "t2.micro"
  key_name      = "MyMentoringProject"
  vpc_security_group_ids = [aws_security_group.my_security_group.id]
}

resource "aws_autoscaling_group" "my_autoscaling_group" {
  desired_capacity   = 2
  max_size           = 3
  min_size           = 1
  
  vpc_zone_identifier = ["subnet-95b42cb4", "subnet-2fc05e70"]
  target_group_arns   = [aws_lb_target_group.my_target_group.arn]
  
  health_check_type         = "ELB"
  health_check_grace_period = 600
  max_instance_lifetime     = 2592000
  

  launch_template {
    id      = aws_launch_template.my_launch_template.id
    version = "$Latest"
  }
}

resource "aws_lb_target_group" "my_target_group" {
  name     = "tf-taret-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = "vpc-3d43ed40"
  
  health_check {
    enabled            = true
	healthy_threshold  = 5
	interval           = 30
	timeout            = 5
	port               = 80
	protocol           = "HTTP"
  }
}

resource "aws_lb_listener" "my_listener" {
  load_balancer_arn = aws_lb.my_lb.id

  default_action {
    target_group_arn = aws_lb_target_group.my_target_group.arn
    type             = "forward"
  }
  port             = 80
  protocol         = "HTTP"
}

resource "aws_autoscaling_attachment" "my_asg_attachment" {
  autoscaling_group_name = aws_autoscaling_group.my_autoscaling_group.id
  alb_target_group_arn = aws_lb_target_group.my_target_group.arn
}

resource "aws_route53_zone" "tf_zone" {
  name = "tfyaroslavdevops.site"
}

resource "aws_route53_record" "record1" {
  zone_id = aws_route53_zone.tf_zone.zone_id
  name    = "www.tfyaroslavdevops.site"
  type    = "CNAME"
  ttl     = "300"
  records = ["tfyaroslavdevops.site"]
}

resource "aws_route53_record" "record2" {
  zone_id = aws_route53_zone.tf_zone.zone_id
  name    = "tfyaroslavdevops.site"
  type    = "A"

  alias {
    name    = aws_lb.my_lb.dns_name
    zone_id = aws_lb.my_lb.zone_id
	evaluate_target_health = false
  }
}

# scale up alarm
resource "aws_autoscaling_policy" "scale-up-policy" {
  name = "scale-up-policy"
  autoscaling_group_name = "my_autoscaling_group"
  adjustment_type = "ChangeInCapacity"
  scaling_adjustment = "1"
  cooldown = "60"
  policy_type = "SimpleScaling"
}

resource "aws_cloudwatch_metric_alarm" "scale-up-alarm" {
  alarm_name = "scale-up-alarm"
  alarm_description = "high-cpu-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods = "1"
  metric_name = "CPUUtilization"
  namespace = "AWS/EC2"
  period = "60"
  statistic = "Average"
  threshold = "75"
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.my_autoscaling_group.name
  }
  actions_enabled = true
  alarm_actions = [aws_autoscaling_policy.scale-up-policy.arn]
}

# scale down alarm
resource "aws_autoscaling_policy" "scale-down-policy" {
  name = "scale-down-policy"
  autoscaling_group_name = "my_autoscaling_group"
  adjustment_type = "ChangeInCapacity"
  scaling_adjustment = "-1"
  cooldown = "60"
  policy_type = "SimpleScaling"
}

resource "aws_cloudwatch_metric_alarm" "example-cpu-alarm-scaledown" {
  alarm_name = "scale-down-alarm"
  alarm_description = "low-cpu-alarm"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods = "1"
  metric_name = "CPUUtilization"
  namespace = "AWS/EC2"
  period = "60"
  statistic = "Average"
  threshold = "25"
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.my_autoscaling_group.name
  }
  actions_enabled = true
  alarm_actions = [aws_autoscaling_policy.scale-down-policy.arn]
}