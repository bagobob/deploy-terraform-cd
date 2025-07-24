resource "aws_iam_policy" "lambda_apigateway_policy" {
  name        = "lambda-apigateway-policy"
  description = "lambda_execution_policy"
  policy = data.aws_iam_policy_document.lambda_execution_policy_document.json

}

data "aws_iam_policy_document" "lambda_execution_policy_document" {
  statement {
    effect    = "Allow"
    actions   = [
        "dynamodb:DeleteItem",
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:Query",
        "dynamodb:Scan",
        "dynamodb:UpdateItem"
        ]
    resources = ["*"]
  }
  statement {
    effect    = "Allow"
    actions   = [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
        ]
    resources = ["*"]
  }
}

data "aws_iam_policy_document" "lambda_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}
resource "aws_iam_role" "lambda_apigateway_role" {
  name = "lambda-apigateway-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role_policy.json
  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "lambda_apigateway_attachment" {
  role       = aws_iam_role.lambda_apigateway_role.name
  policy_arn = aws_iam_policy.lambda_apigateway_policy.arn
}