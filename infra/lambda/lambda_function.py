import boto3
import json

# Define the DynamoDB table
table_name = "lambda-apigateway"
dynamo = boto3.resource('dynamodb').Table(table_name)

# Define CRUD functions
def create(payload):
    return dynamo.put_item(Item=payload['Item'])

def read(payload):
    return dynamo.get_item(Key=payload['Key'])

def update(payload):
    return dynamo.update_item(**{k: payload[k] for k in ['Key', 'UpdateExpression', 
    'ExpressionAttributeNames', 'ExpressionAttributeValues'] if k in payload})

def delete(payload):
    return dynamo.delete_item(Key=payload['Key'])

def echo(payload):
    return payload

operations = {
    'create': create,
    'read': read,
    'update': update,
    'delete': delete,
    'echo': echo,
}

def lambda_handler(event, context):
    try:
        # Parse the JSON body
        body = json.loads(event['body']) if isinstance(event['body'], str) else event['body']
        
        operation = body['operation']
        payload = body['payload']
        
        if operation in operations:
            result = operations[operation](payload)
            return {
                "statusCode": 200,
                "body": json.dumps(result)
            }
        else:
            return {
                "statusCode": 400,
                "body": json.dumps({"error": f"Unrecognized operation '{operation}'"})
            }

    except Exception as e:
        return {
            "statusCode": 500,
            "body": json.dumps({"error": str(e)})
        }
