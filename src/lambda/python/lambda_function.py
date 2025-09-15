import json

def lambda_handler(event, context):
    print("Hello from Python Lambda!")
    
    return {
        'statusCode': 200
    }