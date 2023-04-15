{
aws s3 mb s3://apidata-bucket-rawjson; 
aws s3 mb s3://apidata-bucket-general-files;
aws s3 mb s3://apidata-bucket-transform;
}
wait 

#get build files for lambda get data funciton 
{
curl -o api-func-deployment-package.zip https://raw.githubusercontent.com/DonnieData/aws-pipeline-1/main/lambda/api-func-deployment-package.zip;
aws s3 cp api-func-deployment-package.zip s3://apidata-bucket-general-files
}
wait 

#variables 
{
LAMBDA_EX_ROLE_ARN=$(aws iam get-role --role-name lambda-ex --query 'Role.[Arn]' --output text);
ACCNT_ID=$(aws sts get-caller-identity --query 'Account' --output text)
}
wait 

#lambda execution role
{
aws iam create-role --role-name lambda-ex --assume-role-policy-document \
'{"Version": "2012-10-17","Statement": [{ "Effect": "Allow", "Principal": {"Service": "lambda.amazonaws.com"}, "Action": "sts:AssumeRole"}]}' > /dev/null;
#attach execution policy and s3write 
aws iam attach-role-policy --role-name lambda-ex --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole;
aws iam attach-role-policy --role-name lambda-ex --policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess
} 
wait 

#create lambda function 
{
aws lambda create-function --function-name apidata-lambda-getdata \
--role ${LAMBDA_EX_ROLE_ARN} --runtime python3.9 --handler lambda_function.lambda_handler \
--code S3Bucket=apidata-bucket-general-files,S3Key=api-func-deployment-package.zip > /dev/null;
}
