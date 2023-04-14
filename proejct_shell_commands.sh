# raw data bucket 
aws s3 mb s3://apidata-bucket-rawjson 

#project bucket for misc files 
aws s3 mb s3://apidata-bucket-general-files1

#copy deployment zipfile for lambda  apidata-lambda-getdata
#curl request to download files locally in session; then save to bucket
curl -o api-func-deployment-package.zip https://raw.githubusercontent.com/DonnieData/aws-pipeline-1/main/lambda/api-func-deployment-package.zip;
aws s3 cp api-func-deployment-package.zip s3://apidata-bucket-general-files1

#lambda 
# lambda execution role
aws iam create-role --role-name lambda-ex --assume-role-policy-document '{"Version": "2012-10-17","Statement": [{ "Effect": "Allow", "Principal": {"Service": "lambda.amazonaws.com"}, "Action": "sts:AssumeRole"}]}'


#create lambda funciton --function-name --role
aws lambda create-funciton --apidata-lambda-getdata --lambda-ex

#create funciton then update with runtime, code and dependencies
#then test lamda with cli execution