#ip range to ssh into the ec2 instances in the autoscaling group
lab_cidr_blocks = ["0.0.0.0/0"]

#image id for ec2 instances in the autoscaling group
lab_image_id = "ami-0c5758a904e4ba6e2"

#instance type for ec2 instances in the autoscaling group
lab_instance_type = "t2.micro"

#AWS key pair name 
lab_key_name = "MyMentoringProject"

lab_desired_capacity = 2
lab_max_size         = 3
lab_min_size         = 1

#credentials for the DB admin user
lab_username = "admin"
lab_password  = "adminadmin"

