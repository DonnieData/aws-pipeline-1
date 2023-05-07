#variables 
{
PROJECT_NAME=apidata
ACCNT_ID=$(aws sts get-caller-identity --query 'Account' --output text)
}
wait 

{
aws s3 mb s3://${PROJECT_NAME}-bucket-rawjson; 
aws s3 mb s3://${PROJECT_NAME}-bucket-general-files;
aws s3 mb s3://${PROJECT_NAME}-transform;

}
wait 

# parameter/variable file
#echo '{"project_name":'${PROJECT_NAME}', "account_id": '${ACCNT_ID}'}' > samp.json
#aws s3 cp samp.json s3://${PROJECT_NAME}-bucket-general-files/samp.json

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

aws lambda create-function --function-name ${PROJECT_NAME}-lambda-getdata \
--role ${LAMBDA_EX_ROLE_ARN} --runtime python3.9 --handler lambda_function.lambda_handler \
--code S3Bucket=${PROJECT_NAME}-bucket-general-files,S3Key=api-func-deployment-package.zip \
--environment Variables={raw_data_bucket=${PROJECT_NAME}-bucket-rawjson} > /dev/null;


wait 
LAMBDA_GETDATA_ARN=$(aws lambda get-function --function-name "${PROJECT_NAME}-lambda-getdata" --query 'Configuration.FunctionArn' --output text);


#create policies and add to role  
#upload to cloudshell home directory; use file from home directory as parameter
curl -o lambda-eventbridge-policy.json https://raw.githubusercontent.com/DonnieData/aws-pipeline-1/main/files/lambda-eventbridge-policy.json;
aws iam create-policy \
--policy-name ${PROJECT_NAME}-policy-getdata \
--policy-document file://~/lambda-eventbridge-policy.json;
wait 

#update trust policy 
curl -o lambda-eventbridge-trust-policy.json https://raw.githubusercontent.com/DonnieData/aws-pipeline-1/main/files/lambda-eventbridge-trust-policy.json;
aws iam update-assume-role-policy \
--role-name ${PROJECT_NAME}-lambda-ex \
--policy-document file://~/lambda-eventbridge-trust-policy.json;

wait 
#eventbridge 

#aws events put-rule --name ${PROJECT_NAME}-event-5minutetrigger --schedule-expression "rate(3 minutes)" --state ENABLED 
#--role-arn arn:aws:iam::${ACCNT_ID}:role/${PROJECT_NAME}-lambda-ex
#wait 
#aws events put-targets --rule ${PROJECT_NAME}-event-5minutetrigger \
#--targets "Id"="${PROJECT_NAME}-lambda-getdata","Arn"="arn:aws:lambda:us-east-1:${ACCNT_ID}:function:${PROJECT_NAME}-lambda-getdata";

#---------------
#add event permissions to lambda function
#RULE_ARN=$(aws events list-rules --name ${PROJECT_NAME}-event-5minutetrigger --query 'Rules[0].Arn' --output text)

#aws lambda add-permission --function-name ${PROJECT_NAME}-lambda-getdata \
 #--statement-id lambda1 --action 'lambda:InvokeFunction' --principal events.amazonaws.com --source-arn ${RULE_ARN}


#Glue Role
aws iam create-role --role-name AWSGlueServiceRole-${PROJECT_NAME} --assume-role-policy-document \
'{"Version": "2012-10-17","Statement": [{ "Effect": "Allow", "Principal": {"Service": "glue.amazonaws.com"}, "Action": "sts:AssumeRole"}]}' > /dev/null;

aws iam attach-role-policy --role-name AWSGlueServiceRole-${PROJECT_NAME} --policy-arn arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole;
aws iam attach-role-policy --role-name AWSGlueServiceRole-${PROJECT_NAME} --policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess;
#aws iam attach-role-policy --role-name AWSGlueServiceRole-${PROJECT_NAME} --policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess;

wait 
#----Glue Job
#script for job 
{
curl -o glujob1.py https://raw.githubusercontent.com/DonnieData/aws-pipeline-1/main/glue/gluejob_transform1.py;
aws s3 cp glujob1.py s3://${PROJECT_NAME}-bucket-general-files
}

 #params fro job  cat gluejob1params.json

echo "{
    \"--source_bucket\": \"$PROJECT_NAME-bucket-rawjson\",
    \"--target_bucket\": \"$PROJECT_NAME-transform\"
}" > ~/gluejob1params.json

#create job 
aws glue create-job \
--name gluejob1-${PROJECT_NAME} \
--role AWSGlueServiceRole-${PROJECT_NAME} \
--command Name=pythonshell,ScriptLocation=s3://${PROJECT_NAME}-bucket-general-files/glujob1.py, PythonVersion=3.9; 
#--default-arguments file://~/gluejob1params.json;


#state machine 


#step role polices 
#StepFunctionsExecutionRoleWithXRayAccessPolicy
#StepFunctionsExecutionRoleWithGlueJobRunManagementFullAccessPolicy	
