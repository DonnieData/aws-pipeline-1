#variables 
{
PROJECT_NAME=apidata3
ACCNT_ID=$(aws sts get-caller-identity --query 'Account' --output text)
}
wait 

{
aws s3 mb s3://${PROJECT_NAME}-bucket-rawjson; 
aws s3 mb s3://${PROJECT_NAME}-bucket-general-files;
aws s3 mb s3://${PROJECT_NAME}-transform;
}
wait 

#get build files for lambda get data funciton 
{
curl -o api-func-deployment-package.zip https://raw.githubusercontent.com/DonnieData/aws-pipeline-1/main/lambda/api-func-deployment-package.zip;
aws s3 cp api-func-deployment-package.zip s3://${PROJECT_NAME}-bucket-general-files
}
wait 

#lambda execution role
{
aws iam create-role --role-name ${PROJECT_NAME}-lambda-ex --assume-role-policy-document \
'{"Version": "2012-10-17","Statement": [{ "Effect": "Allow", "Principal": {"Service": "lambda.amazonaws.com"}, "Action": "sts:AssumeRole"}]}' > /dev/null;
#attach execution policy and s3write 
aws iam attach-role-policy --role-name ${PROJECT_NAME}-lambda-ex --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole;
aws iam attach-role-policy --role-name ${PROJECT_NAME}-lambda-ex --policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess
}
LAMBDA_EX_ROLE_ARN=$(aws iam get-role --role-name ${PROJECT_NAME}-lambda-ex --query 'Role.[Arn]' --output text);

sleep 10 

#create lambda function 
{
aws lambda create-function --function-name ${PROJECT_NAME}-lambda-getdata \
--role ${LAMBDA_EX_ROLE_ARN} --runtime python3.9 --handler lambda_function.lambda_handler \
--code S3Bucket=${PROJECT_NAME}-bucket-general-files,S3Key=api-func-deployment-package.zip > /dev/null;
}

LAMBDA_GETDATA_ARN=$(aws lambda get-function --function-name "${PROJECT_NAME}-lambda-getdata" --query 'Configuration.FunctionArn' --output text)

wait 


EVENT_POLICY_JSON="{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "events:PutEvents",
                "lambda:ListFunctions",
                "lambda:InvokeFunction"
            ],
            "Resource": "*"
        }
    ]
}"

------------

#create policy 
aws iam create-policy --policy-name ${PROJECT_NAME}-policy-getdata --policy-document "$EVENT_POLICY_JSON"
#create json. with policy info then can load from s3 


{"Version": "2012-10-17","Statement": [{"Effect": "Allow","Action": "events:PutEvents","Resource": "*"},
{"Effect": "Allow","Action": "lambda:InvokeFunction","Resource": ${LAMBDA_GETDATA_ARN}},{"Effect": "Allow","Action": "lambda:ListFunctions","Resource": "*"}]}

#attach policy to lambda ex 



#need to make lambda function dynamic to get proper bucket 