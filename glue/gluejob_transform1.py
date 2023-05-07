import sys
from awsglue.utils import getResolvedOptions
import os
import json
import boto3
import requests
import time 
import pandas as pd

#get parameters
args = getResolvedOptions(sys.argv,
                          ['source_bucket',
                           'target_bucket',
                           'file_name'
                           ])

#source bucket is a porvided parameter in job json 
#file_name is passed through statemachine payload 
def get_data(bucket, file_name):
    s3_resource = boto3.resource('s3')
    obj = s3_resource.Object(bucket, file_name)
    body = obj.get()['Body'].read().decode('utf-8')
    data = json.loads(body)
    return data


def convert(data):
    df = pd.DataFrame.from_dict(data)
    csv_buffer = df.to_csv(index=False)
    return csv_buffer


def load_data(buffer_data, target_bucket, filename):
    session = boto3.session.Session()
    s3  = session.client('s3')
    s3.put_object(Body=buffer_data, Bucket=target_bucket, Key=filename)


jsondata = get_data(args['source_bucket'], args['file_name'])

csv_buffer = convert(jsondata)
    
transform_name = args['file_name'].strip(".json") +"_transformed.csv"

load_data(csv_buffer, args['target_bucket'] ,transform_name)
