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
`aws ec2 authorize-security-group-ingress --group-name SGforCLITest --protocol tcp --port 80 --cidr 0.0.0.0/0`
`aws ec2 authorize-security-group-ingress --group-name SGforCLITest --protocol tcp --port 22 --cidr 94.131.204.14/32`

Security group for RDS:\
`aws ec2 create-security-group --group-name SGforRDScli --description "My security group for RDS CLI Test"`

Setting up security policies for SGforRDScli:\
`aws ec2 authorize-security-group-ingress --group-name SGforRDScli --protocol tcp --port 3306 --source-group SGforCLITest`
