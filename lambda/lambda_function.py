import json
import boto3
import requests
import time 

def lambda_handler(event, context):
    #time for saving 
    stamp = time.ctime().replace(' ','_')

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
    bucket = s3.Bucket('apidata-bucket-rawjson')
    object_key = f'data_{stamp}.json'
    bucket.put_object(
        Key=object_key,
        Body=json.dumps(data)
    )

    # Return a response
    return {
        'statusCode': 200,
        'body': 'Data saved to S3 bucket'
    }