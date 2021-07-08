provider "aws" {
  profile = "default"
  region  = "us-east-1"
}

module "cloudfront_s3_website" {
  source             = "chgangaraju/cloudfront-s3-website/aws"
  domain_name        = "test-app-782021349"
  use_default_domain = true
}

module "rds-instance" {
  source = "telia-oss/rds-instance/aws"
  
  # insert the 5 required variables here
  name_prefix = "test-app"
  password    = "adminadmin"
  subnet_ids  = ["subnet-95b42cb4", "subnet-2fc05e70"]
  username    = "admin"
  vpc_id      = "vpc-3d43ed40"
  
  # optional vars
  allocated_storage = 20
  apply_immediately = true
  database_name     = "testapp"
  engine            = "mariadb"
  engine_version    = "10.4.13"
  instance_type     = "db.t2.micro"  
  multi_az          = false
  port              = 3306
  storage_encrypted = false
}

resource "aws_db_instance" "test_app_replica" {
   identifier             = "test-app-idn"
   replicate_source_db    = module.rds-instance.id
   instance_class         = "db.t2.micro"
   apply_immediately      = true
   skip_final_snapshot    = true
   vpc_security_group_ids = [module.rds-instance.security_group_id]
}

module "autoscaling" {
  source  = "terraform-aws-modules/autoscaling/aws"

  associate_public_ip_address = true
  disable_api_termination     = false
  ebs_optimized               = false
  force_delete                = false
  health_check_type           = "ELB"
  capacity_rebalance          = false
  default_cooldown            = 60
  desired_capacity            = 2
  health_check_grace_period   = 600
  key_name                    = "MyMentoringProject"
  lt_version                  = "$Latest"
  max_instance_lifetime       = 2592000
  max_size                    = 3
  min_size                    = 1
  name                        = "testapp"
  vpc_zone_identifier         = ["subnet-95b42cb4", "subnet-2fc05e70"]
  image_id                    = "ami-0c5758a904e4ba6e2"
  instance_type               = "t2.micro"
  lt_name                     = "testapp"
  security_groups             = ["sg-0a2163b80361fc134"]
  target_group_arns           = [module.lb-target-group.target_group_arn]

  use_lt    = true
  create_lt = true
}

module "alb" {
  source  = "umotif-public/alb/aws"

  name_prefix = "testapp"
  subnets     = ["subnet-95b42cb4", "subnet-2fc05e70"]
  vpc_id      = "vpc-3d43ed40"
  
}

module "lb-target-group" {
  source  = "StratusGrid/lb-target-group/aws"
  
  vpc_id = "vpc-3d43ed40"
  
  target_group_name_prefix            = "testapp"
  target_group_hc_healthy_threshold   = "5"
  target_group_hc_unhealthy_threshold = "5"
  target_group_health_interval        = "30"
  target_group_health_port            = "80"
  target_group_health_protocol        = "HTTP"
  target_group_health_timeout         = "5"
  target_group_port                   = "80"
  target_group_protocol               = "HTTP"
  target_group_type                   = "instance"
}

module "alb-http-listener" {
  source  = "deepak7093/alb-http-listener/aws"

  alb_arn          = module.alb.arn
  port             = "80"
  target_group_arn = module.lb-target-group.target_group_arn
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
    name    = module.alb.dns_name
    zone_id = module.alb.zone_id
	evaluate_target_health = false
  }
}