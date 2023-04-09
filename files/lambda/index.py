import json
import boto3
import requests

def lambda_handler(event, context):
    # Make API request using requests library
    response = requests.get('https://www.dallasopendata.com/resource/d7e7-envw.json?$limit=25')

    # Get the response data
    data = response.json()

    # Check if data was retrieved
    if len(data) <= 1:
        return {
            'statusCode': 404,
            'body': 'No data was retrieved from the API'
        }

    # Save the data to S3 bucket
    s3 = boto3.resource('s3')
    bucket = s3.Bucket('apidatabucket45')
    object_key = 'data.json'
    bucket.put_object(
        Key=object_key,
        Body=json.dumps(data)
    )

    # Return a response
    return {
        'statusCode': 200,
        'body': 'Data saved to S3 bucket'
    }
