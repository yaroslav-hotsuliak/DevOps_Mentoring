**Create S3**

Create s3 bucket:\
`aws s3 mb s3://mywebsitecli-test`

Upload files to s3 bucket:\
`aws s3 cp Clean_Template s3://mywebsitecli-test/ --recursive --acl public-read-write`

Configure s3 bucket as a static website:\
`aws s3 website s3://mywebsitecli-test/ --index-document index.html`

**Create Cloudfront**

Create cloudfront distribution:\
`aws cloudfront create-distribution --origin-domain-name mywebsitecli-test.s3-website-us-east-1.amazonaws.com`

**Security Groups**

Security group for CLITest:\
`aws ec2 create-security-group --group-name SGforCLITest --description "My security group for CLI Test"`

Setting up security policies for SGforCLITest:\
`aws ec2 authorize-security-group-ingress --group-name SGforCLITest --protocol tcp --port 80 --cidr 0.0.0.0/0`\
`aws ec2 authorize-security-group-ingress --group-name SGforCLITest --protocol tcp --port 22 --cidr 94.131.204.14/32`

Security group for RDS:\
`aws ec2 create-security-group --group-name SGforRDScli --description "My security group for RDS CLI Test"`

Setting up security policies for SGforRDScli:\
`aws ec2 authorize-security-group-ingress --group-name SGforRDScli --protocol tcp --port 3306 --source-group SGforCLITest`

**Create Auto Scaling group**

Create a launch template:\
`aws ec2 create-launch-template --launch-template-name launch-template-cli --version-description version1 ^`\
  `--launch-template-data "{\"ImageId\":\"ami-0533f2ba8a1995cf9\",\"InstanceType\":\"t2.micro\",\"SecurityGroupIds\":[\"sg-086846f0e9429ae63\"]}"`\
"lt-08ea52d5fbe133e43"

Create a load balancer:\
`aws elbv2 create-load-balancer --name load-balancer-cli-test --subnets subnet-95b42cb4 subnet-2fc05e70 --security-groups sg-086846f0e9429ae63`\
"arn:aws:elasticloadbalancing:us-east-1:345145124555:loadbalancer/app/load-balancer-cli-test/dcf437696dac6526"

Create a target group:\
`aws elbv2 create-target-group --name target-group-cli --protocol HTTP --port 80 --vpc-id vpc-3d43ed40`\
"arn:aws:elasticloadbalancing:us-east-1:345145124555:targetgroup/target-group-cli/26f7b021a662bc0d"

Create a listener for the load balancer:\
`aws elbv2 create-listener --load-balancer-arn arn:aws:elasticloadbalancing:us-east-1:345145124555:loadbalancer/app/load-balancer-cli-test/dcf437696dac6526 --protocol HTTP --port 80 --default-actions Type=forward,TargetGroupArn=arn:aws:elasticloadbalancing:us-east-1:345145124555:targetgroup/target-group-cli/26f7b021a662bc0d`\
"arn:aws:elasticloadbalancing:us-east-1:345145124555:listener/app/load-balancer-cli-test/dcf437696dac6526/3ad57d9479ee5742"

Create an auto scaling group:\
`aws autoscaling create-auto-scaling-group --auto-scaling-group-name asg-cli --launch-template LaunchTemplateId=lt-08ea52d5fbe133e43 --target-group-arns arn:aws:elasticloadbalancing:us-east-1:345145124555:targetgroup/target-group-cli/26f7b021a662bc0d --health-check-type ELB --health-check-grace-period 600 --min-size 1 --max-size 3 --desired-capacity 2 --vpc-zone-identifier "subnet-95b42cb4,subnet-2fc05e70"`

Create an autoscaling policy:\
`aws autoscaling put-scaling-policy --policy-name cpu40-target-tracking-scaling-policy ^`\
  `--auto-scaling-group-name asg-cli --policy-type TargetTrackingScaling ^`\
  `--target-tracking-configuration file://scaling-policy.js`
  
**RDS**

Create an RDS:\
`aws rds create-db-instance ^`\
  `--db-name clitestdb ^`\
  `--db-instance-identifier cli-test-db ^`\
  `--db-instance-class db.t2.micro ^`\
  `--engine mariadb ^`\
  `--master-username admin ^`\
  `--master-user-password adminadmin ^`\
  `--allocated-storage 20 ^`\
	`--availability-zone us-east-1f ^`\
	`--db-subnet-group-name default-vpc-3d43ed40 ^`\
	`--engine-version 10.4.13 ^`\
	`--max-allocated-storage 1000 ^`\
	`--no-publicly-accessible`
	
Created Read Replica for DB:\
`aws rds create-db-instance-read-replica --db-instance-identifier cli-test-db-repl --source-db-instance-identifier cli-test-db`

**Route 53**

Create a hosted zone:\
`aws route53 create-hosted-zone --name cliyaroslavdevops.site --caller-reference 2021-04-20-18:47 ^`\
    `--hosted-zone-config "{\"Comment\":\"cli-test\",\"PrivateZone\":false}"`
