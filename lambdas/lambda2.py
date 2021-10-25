import json
import boto3

def lambda_handler(event, context):

    message_string = ""
    for record in event['Records']:
        message_string += record['body'] + ", "
        print("Recieved message body: " + record['body'])
    return {
        'statusCode': 200,
        'body': json.dumps("Recieved messages: " + message_string)
    }
