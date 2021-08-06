
provider "aws" {
  region = "eu-west-1"
}

# Create a DynamoDB Table

resource "aws_dynamodb_table" "product-collections-table" {
  name           = "ProductCollections"
  billing_mode   = "PROVISIONED"
  read_capacity  = 20
  write_capacity = 20
  hash_key       = "id"
  #   range_key      = "CollectionName"

  attribute {
    name = "id"
    type = "S"
  }


  tags = {
    Name    = "product-collections-table"
    Project = "Hack Day: Product Collections"
  }
}

# Create a Log Group for API Gateway 

resource "aws_cloudwatch_log_group" "product-collections-api-log-group" {
  name              = "product-collections-api-log-group"
  retention_in_days = 3
  tags = {
    Name    = "Product Collects API Logs"
    Project = "Hack Day Product Collections"
  }
}



# Create Lambda Function in prep for the Dynamo DB

resource "aws_iam_role" "iam_for_product-collections_lambda" {
  name               = "iam_for_product-collections_lambda"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    } 
  ]
}
EOF
}

# This is to optionally manage the CloudWatch Log Group for the Lambda Function.
# If skipping this resource configuration, also add "logs:CreateLogGroup" to the IAM policy below.
resource "aws_cloudwatch_log_group" "product-collection_lambda-logs" {
  name              = "product-collection-lambda"
  retention_in_days = 3
}

# See also the following AWS managed policy: AWSLambdaBasicExecutionRole
resource "aws_iam_policy" "lambda_logging" {
  name        = "lambda_logging"
  path        = "/"
  description = "IAM policy for logging from a lambda"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*",
      "Effect": "Allow"
    }, 
    { 
      "Action": [
        "dynamodb:DeleteItem",
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:Scan"
      ],
      "Resource": "${aws_dynamodb_table.product-collections-table.arn}",
      "Effect": "Allow"
    }
  ]
}
EOF
}


resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.iam_for_product-collections_lambda.name
  policy_arn = aws_iam_policy.lambda_logging.arn
}

resource "aws_lambda_function" "product-collections-lambda" {
  filename      = "lambda.zip"
  function_name = "product-collections-lambda"
  role          = aws_iam_role.iam_for_product-collections_lambda.arn
  handler       = "index.handler" # The name of the function - not the file name!

  # The filebase64sha256() function is available in Terraform 0.11.12 and later
  source_code_hash = filebase64sha256("lambda.zip")

  runtime = "nodejs14.x"

  timeout = 15

  depends_on = [
    aws_iam_role_policy_attachment.lambda_logs,
    aws_cloudwatch_log_group.product-collection_lambda-logs,
  ]

  tags = {
    Name    = "Product Collections Lambda function"
    Project = "Hack Day: Product Collections"
  }
}


# Create API Gateway

resource "aws_apigatewayv2_api" "product-collections" {
  name          = "product-collections-http-api"
  protocol_type = "HTTP"

  version = 1

  tags = {
    "Project" = "Hack Day: Product Collections"
    "Name"    = "Product Collections API"
  }
}

resource "aws_apigatewayv2_integration" "product-collections-api-integration" {
  api_id           = aws_apigatewayv2_api.product-collections.id
  integration_type = "AWS_PROXY"
  integration_uri  = aws_lambda_function.product-collections-lambda.invoke_arn
  description      = "Product Collections Lambda Integration"
}

resource "aws_apigatewayv2_stage" "product-collections-api-stage" {
  api_id      = aws_apigatewayv2_api.product-collections.id
  name        = "$default"
  auto_deploy = true
  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.product-collections-api-log-group.arn
    format          = "{ \"requestId\":\"$context.requestId\", \"ip\": \"$context.identity.sourceIp\", \"requestTime\":\"$context.requestTime\", \"httpMethod\":\"$context.httpMethod\",\"routeKey\":\"$context.routeKey\", \"status\":\"$context.status\",\"protocol\":\"$context.protocol\", \"responseLength\":\"$context.responseLength\", \"integrationError\":\"$context.integrationErrorMessage\" }"
  }
}

resource "aws_apigatewayv2_route" "product-collections-get-all" {
  api_id    = aws_apigatewayv2_api.product-collections.id
  route_key = "GET /items"
  target    = "integrations/${aws_apigatewayv2_integration.product-collections-api-integration.id}"
}

resource "aws_apigatewayv2_route" "product-collections-get-one" {
  api_id    = aws_apigatewayv2_api.product-collections.id
  route_key = "GET /items/{id}"
  target    = "integrations/${aws_apigatewayv2_integration.product-collections-api-integration.id}"
}

resource "aws_apigatewayv2_route" "product-collections-delete-one" {
  api_id    = aws_apigatewayv2_api.product-collections.id
  route_key = "DELETE /items/{id}"
  target    = "integrations/${aws_apigatewayv2_integration.product-collections-api-integration.id}"
}

resource "aws_apigatewayv2_route" "product-collections-create-update" {
  api_id    = aws_apigatewayv2_api.product-collections.id
  route_key = "PUT /items"
  target    = "integrations/${aws_apigatewayv2_integration.product-collections-api-integration.id}"
}

# Output the API url

output "api_url" {
  value = aws_apigatewayv2_stage.product-collections-api-stage.invoke_url
}
