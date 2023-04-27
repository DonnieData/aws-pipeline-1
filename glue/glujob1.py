#script that gets buckets via substring searching 
#a quick fix for now 
import sys
from awsglue.utils import getResolvedOptions
import os
import json
import boto3
import requests
import time 
import pandas as pd

args = getResolvedOptions(sys.argv,
                          ['source_bucket',
                           'target_bucket'
                          ])

#currrent solution for getting bucket name
def get_source_file(source_folder):
    session = boto3.session.Session()
    s3  = session.client('s3')
    #bucket_info = s3.list_buckets()
    #index_list = list(range(len(bucket_info['Buckets'])))
    #bucket_names = [bucket_info['Buckets'][i]['Name'] for i in index_list]
    object_info = s3.list_objects_v2(Bucket=source_folder)
    json_files = [i['Key'] for i in object_info['Contents']]
    json_file = json_files[1]
    
    return json_file 

def get_data(bucket,file):
    s3_resource = boto3.resource('s3')
    bucket_name = bucket
    key = file
    obj = s3_resource.Object(bucket_name, key)
    body = obj.get()['Body'].read().decode('utf-8')
    data = json.loads(body)
    return data

def convert(data):
    df = pd.DataFrame.from_dict(data)
    csv_buffer = df.to_csv(index=False)
    return csv_buffer

def get_target_bucket():
    session = boto3.session.Session()
    s3  = session.client('s3')
    bucket_info = s3.list_buckets()
    index_list = list(range(len(bucket_info['Buckets'])))
    bucket_names = [bucket_info['Buckets'][i]['Name'] for i in index_list]
    target_bucket  = [i for i in bucket_names if "transform" in i][0]
    return target_bucket

def load_data(buffer_data,target_bucket,filename):
    session = boto3.session.Session()
    s3  = session.client('s3')
    s3.put_object(Body=buffer_data, Bucket=target_bucket, Key=new_name)


    
json_file = get_source_file(args['source_bucket'])

new_name = json_file.strip(".json") +"_transformed.csv"

data = get_data(args['source_bucket'], json_file)

csv_buffer = convert(data)

target_bucket = get_target_bucket()

load_data(csv_buffer,args['target_bucket'],new_name)