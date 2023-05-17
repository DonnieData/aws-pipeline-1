#create buckets, vars  
{
PROJECT_NAME=apidata
ACCNT_ID=$(aws sts get-caller-identity --query 'Account' --output text)
aws s3 mb s3://${PROJECT_NAME}-bucket-general-files
}

wait 

#lambda and glue code, cfn template
{

#curl -o parameters.json 
#aws s3 cp parameters.json s3://${PROJECT_NAME}-bucket-general-files

echo "{
    \"ParameterKey\": \"projectName\",
    \"ParameterValue\": \"$PROJECT_NAME\"
}" > ~/cfnparams.json


curl -o api-func-deployment-package.zip https://raw.githubusercontent.com/DonnieData/aws-pipeline-1/main/lambda/api-func-deployment-package.zip;
aws s3 cp api-func-deployment-package.zip s3://${PROJECT_NAME}-bucket-general-files

curl -o glujob1.py https://raw.githubusercontent.com/DonnieData/aws-pipeline-1/main/glue/glujob1.py;
aws s3 cp glujob1.py s3://${PROJECT_NAME}-bucket-general-files

curl -o template.yml https://raw.githubusercontent.com/DonnieData/aws-pipeline-1/main/files/template.yml;
aws s3 cp template.yml s3://${PROJECT_NAME}-bucket-general-files

}
wait 


# deploy cfn  stack  

aws cloudformation package --template-file template.yml \ 
--s3-bucket s3://${PROJECT_NAME}-bucket-general-files