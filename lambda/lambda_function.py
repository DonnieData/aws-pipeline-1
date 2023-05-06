import os
import json
import boto3
import requests
import time 

def lambda_handler(event, context):
    result = {}
    #get correct bucket name 
    raw_data_bucket_name = os.environ.get("raw_data_bucket")
    #time for saving 
    stamp = time.ctime().replace(' ','_')

    # Make API request using requests library
    response = requests.get('https://www.dallasopendata.com/resource/d7e7-envw.json?$limit=25')

    # Get the response data
    data = response.json()

    # Check if data was retrieved
    if len(data) <= 1:
        result['STATUS'] = 'failed'

    # Save the data to S3 bucket
    s3 = boto3.resource('s3')
    bucket = s3.Bucket(raw_data_bucket_name)
    object_key = f'data_{stamp}.json'
    bucket.put_object(
        Key=object_key,
        Body=json.dumps(data)
    )

    result['STATUS'] = "success"
    result['file_name'] = object_key
    # Return a response

    return result