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
  subnets            = [subnet-95b42cb4, subnet-2fc05e70]
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
  
  vpc_zone_identifier = [subnet-95b42cb4, subnet-2fc05e70]
  target_group_arns   =
  

  launch_template {
    id      = aws_launch_template.my_launch_template.id
    version = "$Latest"
  }
}