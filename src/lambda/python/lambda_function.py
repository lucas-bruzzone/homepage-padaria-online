import json

def lambda_handler(event, context):
    print("Hello from Python Lambda!")
    
    return {
        'statusCode': 200,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*'
        },
        'body': json.dumps({
            'message': 'Hello World from Python Lambda!',
            'environment': context.get('environment', 'development')
        })
    }