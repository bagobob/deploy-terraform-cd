resource "aws_api_gateway_rest_api" "dynamo_db_operations" {
  name = "DynamoDBOperations"
   endpoint_configuration {
    types = ["REGIONAL"]
  }
  tags = var.tags
}

resource "aws_api_gateway_resource" "dynamodb_manager" {
  parent_id   = aws_api_gateway_rest_api.dynamo_db_operations.root_resource_id
  path_part   = "DynamoDBManager"
  rest_api_id = aws_api_gateway_rest_api.dynamo_db_operations.id
}

data "aws_caller_identity" "current" {}

resource "aws_lambda_permission" "apigw_lambda" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_function_over_https.function_name
  principal     = "apigateway.amazonaws.com"

  # More: http://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-control-access-using-iam-policies-to-invoke-api.html
  source_arn = "${aws_api_gateway_rest_api.dynamo_db_operations.execution_arn}/*/*"
}

resource "aws_api_gateway_deployment" "dynamodb_manager" {
  rest_api_id = aws_api_gateway_rest_api.dynamo_db_operations.id

  triggers = {
    # NOTE: The configuration below will satisfy ordering considerations,
    #       but not pick up all future REST API changes. More advanced patterns
    #       are possible, such as using the filesha1() function against the
    #       Terraform configuration file(s) or removing the .id references to
    #       calculate a hash against whole resources. Be aware that using whole
    #       resources will show a difference after the initial implementation.
    #       It will stabilize to only change when resources change afterwards.
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.dynamodb_manager.id,
      aws_api_gateway_method.post_method.id,
      aws_api_gateway_integration.post_method.id,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "dynamodb_manager" {
  deployment_id = aws_api_gateway_deployment.dynamodb_manager.id
  rest_api_id   = aws_api_gateway_rest_api.dynamo_db_operations.id
  stage_name    = "dev"
}

# POST METHOD
resource "aws_api_gateway_method" "post_method" {
  authorization = "NONE"
  http_method   = "POST"
  resource_id   = aws_api_gateway_resource.dynamodb_manager.id
  rest_api_id   = aws_api_gateway_rest_api.dynamo_db_operations.id
}

resource "aws_api_gateway_method_response" "response_200" {
  rest_api_id = aws_api_gateway_rest_api.dynamo_db_operations.id
  resource_id = aws_api_gateway_resource.dynamodb_manager.id
  http_method = aws_api_gateway_method.post_method.http_method
  status_code = "200"
}

resource "aws_api_gateway_integration" "post_method" {
  http_method = aws_api_gateway_method.post_method.http_method
  resource_id = aws_api_gateway_resource.dynamodb_manager.id
  rest_api_id = aws_api_gateway_rest_api.dynamo_db_operations.id
   integration_http_method = "POST"
   type                    = "AWS_PROXY"
   uri                     = aws_lambda_function.lambda_function_over_https.invoke_arn
}

resource "aws_api_gateway_integration_response" "post_method" {
  rest_api_id = aws_api_gateway_rest_api.dynamo_db_operations.id
  resource_id = aws_api_gateway_resource.dynamodb_manager.id
  http_method = aws_api_gateway_method.post_method.http_method
  status_code = aws_api_gateway_method_response.response_200.status_code


  depends_on = [
    aws_api_gateway_integration.post_method
  ]
}

# OPTIONS FOR CORS

# resource "aws_api_gateway_method" "option_method" {
#   authorization = "NONE"
#   http_method   = "OPTIONS"
#   resource_id   = aws_api_gateway_resource.dynamodb_manager.id
#   rest_api_id   = aws_api_gateway_rest_api.dynamo_db_operations.id
# }


# resource "aws_api_gateway_integration" "options_method" {
#   http_method = aws_api_gateway_method.post_method.http_method
#   resource_id = aws_api_gateway_resource.dynamodb_manager.id
#   rest_api_id = aws_api_gateway_rest_api.dynamo_db_operations.id
#    integration_http_method = "POST"
#    type                    = "MOCK"
# }
# resource "aws_api_gateway_method_response" "options" {
#   rest_api_id = aws_api_gateway_rest_api.dynamo_db_operations.id
#   resource_id = aws_api_gateway_resource.dynamodb_manager.id
#   http_method = aws_api_gateway_method.option_method.http_method
#   status_code = "200"

#   response_parameters = {
#     "method.response.header.Access-Control-Allow-Headers" = false
#     "method.response.header.Access-Control-Allow-Methods" = false
#     "method.response.header.Access-Control-Allow-Origin"  = false
#   }
#   response_models = {
#     "application/json" = "Empty"
#   }

# }

# resource "aws_api_gateway_integration_response" "options" {
#   rest_api_id = aws_api_gateway_rest_api.dynamo_db_operations.id
#   resource_id = aws_api_gateway_resource.dynamodb_manager.id
#   http_method = aws_api_gateway_method.option_method.http_method
#   status_code = aws_api_gateway_method_response.options.status_code

#   response_parameters = {
#     "method.response.header.Access-Control-Allow-Headers" =  "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'",
#     "method.response.header.Access-Control-Allow-Methods" = "'GET,OPTIONS,POST,PUT'",
#     "method.response.header.Access-Control-Allow-Origin" = "'*'"
# }

#   depends_on = [
#     aws_api_gateway_method.option_method,
#     aws_api_gateway_integration.options_method
#   ]
# }