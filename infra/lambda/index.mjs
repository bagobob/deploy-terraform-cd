import { DynamoDBDocumentClient, PutCommand, GetCommand, 
         UpdateCommand, DeleteCommand} from "@aws-sdk/lib-dynamodb";
import { DynamoDBClient } from "@aws-sdk/client-dynamodb";

const ddbClient = new DynamoDBClient({ region: "eu-west-1" });
const ddbDocClient = DynamoDBDocumentClient.from(ddbClient);

// Define the name of the DDB table to perform the CRUD operations on
const tablename = "lambda-apigateway";

/**
 * Provide an event that contains the following keys:
 *
 *   - operation: one of 'create,' 'read,' 'update,' 'delete,' or 'echo'
 *   - payload: a JSON object containing the parameters for the table item
 *     to perform the operation on
 */
export const handler = async (event) => {
  let body;

  // Vérifier si event.body est une chaîne JSON, et la parser
  try {
    body = typeof event.body === "string" ? JSON.parse(event.body) : event.body;
  } catch (err) {
    return {
      statusCode: 400,
      body: JSON.stringify({ message: "Invalid JSON in request body", error: err.message })
    };
  }

  const operation = body?.operation;
  const payload = body?.payload;

  if (!operation) {
    return {
      statusCode: 500,
      body: JSON.stringify({ message: "Internal server error", error: "Missing 'operation' in request body" })
    };
  }

  if (!payload) {
    return {
      statusCode: 500,
      body: JSON.stringify({ message: "Internal server error", error: "Missing 'payload' in request body" })
    };
  }

  payload.TableName = tablename;

  try {
    let response;

    switch (operation) {
      case "create":
        response = await ddbDocClient.send(new PutCommand(payload));
        break;
      case "read":
        response = await ddbDocClient.send(new GetCommand(payload));
        break;
      case "update":
        response = await ddbDocClient.send(new UpdateCommand(payload));
        break;
      case "delete":
        response = await ddbDocClient.send(new DeleteCommand(payload));
        break;
      case "echo":
        response = payload;
        break;
      default:
        return {
          statusCode: 400,
          body: JSON.stringify({ message: `Unknown operation '${operation}'` })
        };
    }

    return {
      statusCode: 200,
      body: JSON.stringify({ message: "Success", data: response })
    };
  } catch (err) {
    return {
      statusCode: 500,
      body: JSON.stringify({ message: "Internal server error", error: err.message })
    };
  }
};
