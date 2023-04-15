#redshift


#S3
# buckets
aws s3 mb s3://apidata-bucket-rawjson; 
aws s3 mb s3://apidata-bucket-general-files;
aws s3 mb s3://apidata-bucket-transform;


#copy deployment zipfile for lambda  apidata-lambda-getdata
#curl request to download files locally in session; then save to bucket
curl -o api-func-deployment-package.zip https://raw.githubusercontent.com/DonnieData/aws-pipeline-1/main/lambda/api-func-deployment-package.zip;
aws s3 cp api-func-deployment-package.zip s3://apidata-bucket-general-files

#LAMBDA 
# create lambda execution role with trust policy 
aws iam create-role --role-name lambda-ex --assume-role-policy-document \
'{"Version": "2012-10-17","Statement": [{ "Effect": "Allow", "Principal": {"Service": "lambda.amazonaws.com"}, "Action": "sts:AssumeRole"}]}' > /dev/null;
#attach execution policy and s3write 
aws iam attach-role-policy --role-name lambda-ex --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole;
aws iam attach-role-policy --role-name lambda-ex --policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess

#get ARN of execution role ; needed for function creation 
LAMBDA_EX_ROLE_ARN=$(aws iam get-role --role-name lambda-ex --query 'Role.[Arn]' --output text)

#create lambda function --function-name --role
aws lambda create-function --function-name apidata-lambda-getdata \
--role ${LAMBDA_EX_ROLE_ARN} --runtime python3.9 --handler lambda_function.lambda_handler \
--code S3Bucket=apidata-bucket-general-files,S3Key=api-func-deployment-package.zip > /dev/null;


#invoke function
aws lambda invoke --function-name apidata-lambda-getdata -

ACCNT_ID=$(aws sts get-caller-identity --query 'Account' --output text)

#create eventbridge rule; add a target to the rule; grant permission to lambda function 



aws events put-rule --name ${PROJECT_NAME}-event-5minutetrigger --schedule-expression "rate(5 minutes)" --state ENABLED;
aws events put-targets --rule ${PROJECT_NAME}-event-5minutetrigger \
--targets "Id"="${PROJECT_NAME}-lambda-getdata","Arn"="arn:aws:lambda:us-east-1:${ACCNT_ID}:function:${PROJECT_NAME}-lambda-getdata"