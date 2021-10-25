import json
import os
import base64
import string
import random
import boto3

QUEUE_URL = os.environ['QUEUE_URL']

def lambda_handler(event,context):
    content = "<h3>Hello there "+event['headers']['x-forwarded-for']+" using "+event['headers']['user-agent']+"</h3><h2>... my favorite food is "+os.environ['MY_CONSTANT']+"</h2>"
    print("Hello there", format(event['headers']['x-forwarded-for']), "using ", format(event['headers']['user-agent']), "... my favorite food is ", os.environ['MY_CONSTANT'])
    post_content = event['headers']['x-forwarded-for']+" /// "+event['headers']['user-agent']
    sqs = boto3.client('sqs')
   
    try:
        response = sqs.send_message(
            QueueUrl=QUEUE_URL,
            MessageBody=str(post_content),
            DelaySeconds=0
        )
        print (response)   
    except Exception as e:
        raise IOError(e)
        
    return { 
        'body': content,
        'headers': {
            'Content-Type': 'text/html' 
        },
        
        'statusCode': 200
    }
  
