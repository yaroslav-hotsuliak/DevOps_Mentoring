#ip range to ssh into the ec2 instances in the autoscaling group
lab_cidr_blocks = ["0.0.0.0/0"]

#image id for ec2 instances in the autoscaling group
lab_image_id = "ami-06e718d9bcd5f288c"

#instance type for ec2 instances in the autoscaling group
lab_instance_type = "t2.micro"

#AWS key pair name 
lab_key_name = "Cloudformation_key"

lab_desired_capacity = 2
lab_max_size         = 3
lab_min_size         = 1

#credentials for the DB admin user
lab_username = "admin"
lab_password  = "adminadmin"
