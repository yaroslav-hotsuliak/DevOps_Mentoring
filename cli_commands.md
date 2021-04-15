**#Create S3

#create s3 bucket
aws s3 mb s3://mywebsitecli-test

#upload files to s3 bucket
aws s3 cp Clean_Template s3://mywebsitecli-test/ --recursive --acl public-read-write

#configure s3 bucket as a static website 
aws s3 website s3://mywebsitecli-test/ --index-document index.html

**#Create Cloudfront

#Create cloudfront distribution
aws cloudfront create-distribution --origin-domain-name mywebsitecli-test.s3-website-us-east-1.amazonaws.com


