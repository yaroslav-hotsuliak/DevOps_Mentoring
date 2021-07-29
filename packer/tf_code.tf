#use the follwoing command prior runnig terraform template to encode user data: base64 user_data.sh > user_data64.sh 

variable "lab_cidr_blocks" {
  type = list(string)
}
variable "lab_image_id" {
  type = string
}
variable "lab_instance_type" {
  type = string
}
variable "lab_key_name" {
  type = string
}
variable "lab_desired_capacity" {
  type = number
}
variable "lab_max_size" { 
  type = number
}
variable "lab_min_size" {
  type = number
}
variable "lab_username" {
  type = string
}
variable "lab_password" {
  type = string
}

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
    cidr_blocks      = var.lab_cidr_blocks
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
  image_id      = var.lab_image_id
  instance_type = var.lab_instance_type
  key_name      = var.lab_key_name
  vpc_security_group_ids = [aws_security_group.my_security_group.id]
  user_data = filebase64("user_data64.sh")
}

resource "aws_autoscaling_group" "my_autoscaling_group" {
  desired_capacity   = var.lab_desired_capacity
  max_size           = var.lab_max_size
  min_size           = var.lab_min_size
  
  vpc_zone_identifier = ["subnet-95b42cb4", "subnet-2fc05e70"]
  target_group_arns   = [aws_lb_target_group.my_target_group.arn]
  
# health_check_type         = "ELB"
# health_check_grace_period = 600
  max_instance_lifetime     = 2592000
  

  launch_template {
    id      = aws_launch_template.my_launch_template.id
    version = "$Latest"
  }
  depends_on = [
    aws_db_instance.my_db
  ]
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

#resource "aws_route53_zone" "tf_zone" {
#  name = "tfyaroslavdevops.site"
#}

#resource "aws_route53_record" "record1" {
#  zone_id = aws_route53_zone.tf_zone.zone_id
#  name    = "www.tfyaroslavdevops.site"
#  type    = "CNAME"
#  ttl     = "300"
#  records = ["tfyaroslavdevops.site"]
#}

#resource "aws_route53_record" "record2" {
#  zone_id = aws_route53_zone.tf_zone.zone_id
#  name    = "tfyaroslavdevops.site"
#  type    = "A"
#
#  alias {
#    name    = aws_lb.my_lb.dns_name
#    zone_id = aws_lb.my_lb.zone_id
#	evaluate_target_health = false
#  }
#}

# scale up alarm
resource "aws_autoscaling_policy" "scale-up-policy" {
  name = "scale-up-policy"
  autoscaling_group_name = aws_autoscaling_group.my_autoscaling_group.name
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
    "AutoScalingGroupName" = "aws_autoscaling_group.my_autoscaling_group.name" 
  }
  actions_enabled = true
  alarm_actions = [aws_autoscaling_policy.scale-up-policy.arn]
}

# scale down alarm
resource "aws_autoscaling_policy" "scale-down-policy" {
  name = "scale-down-policy"
  autoscaling_group_name = aws_autoscaling_group.my_autoscaling_group.name
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
    "AutoScalingGroupName" = "aws_autoscaling_group.my_autoscaling_group.name"
  }
  actions_enabled = true
  alarm_actions = [aws_autoscaling_policy.scale-down-policy.arn]
}

#resource "aws_s3_bucket" "my_bucket" {
#  bucket = "tf-my-bucket-6152021"
#  acl    = "public-read"
#
#  website {
#  index_document = "index.html"
#  }
#}


#locals {
#  s3_origin_id = "myS3Origin"
#}

#resource "aws_cloudfront_distribution" "my_distribution" {
#  origin {
#    domain_name = aws_s3_bucket.my_bucket.bucket_regional_domain_name
#    origin_id   = local.s3_origin_id
#  }
#
#  enabled             = true
#  default_root_object = "index.html"
#
#  default_cache_behavior {
#    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
#    cached_methods   = ["GET", "HEAD"]
#    target_origin_id = local.s3_origin_id
#
#    forwarded_values {
#      query_string = false
#
#      cookies {
#        forward = "none"
#      }
#    }
#    
#    viewer_protocol_policy = "allow-all"
#    min_ttl                = 0
#    default_ttl            = 3600
#    max_ttl                = 86400
#  }
#  
#  price_class = "PriceClass_All"
#  
#  restrictions {
#    geo_restriction {
#      restriction_type = "none"
#    }
#  }
#
#  viewer_certificate {
#    cloudfront_default_certificate = true
#  }
#}

resource "aws_security_group" "my_security_group_db" {
  name        = "tf-security-group-db"
  description = "DB security group"

  ingress {
    description      = "allow mysql"
    from_port        = 3306
    to_port          = 3306
    protocol         = "tcp"
    security_groups  = [aws_security_group.my_security_group.id]
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }
}

resource "aws_db_instance" "my_db" {
  allocated_storage       = 20
  engine                  = "mariadb"
  engine_version          = "10.4.13"
  instance_class          = "db.t2.micro"
  name                    = "TFmydb"
  identifier              = "tf-mydb-idf" 
  username                = var.lab_username
  password                = var.lab_password
  skip_final_snapshot     = true
  vpc_security_group_ids  = [aws_security_group.my_security_group_db.id]
  backup_retention_period = 1
}

#resource "aws_db_instance" "my_db_replica" {
#   identifier             = "tf-mydb-idf-replica"
#   replicate_source_db    = aws_db_instance.my_db.identifier
#   instance_class         = "db.t2.micro"
#   apply_immediately      = true
#   skip_final_snapshot    = true
#   vpc_security_group_ids = [aws_security_group.my_security_group_db.id]
#}