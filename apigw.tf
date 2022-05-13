// Create AWS API Gateway Resources
resource "aws_api_gateway_rest_api" "apigw" {
  name        = "apigw_sqs"
  description = "API Gateway POST records to SQS"
}

resource "aws_api_gateway_resource" "resource" {
  rest_api_id = aws_api_gateway_rest_api.apigw.id
  parent_id   = aws_api_gateway_rest_api.apigw.root_resource_id
  path_part   = "apigw_resource"
}

resource "aws_api_gateway_request_validator" "validator" {
  name                        = "queryValidator"
  rest_api_id                 = aws_api_gateway_rest_api.apigw.id
  validate_request_body       = false
  validate_request_parameters = true
}

resource "aws_api_gateway_method" "method" {
    rest_api_id   = aws_api_gateway_rest_api.apigw.id
    resource_id   = aws_api_gateway_resource.resource.id
    http_method   = "POST"
    authorization = "NONE"

    request_parameters = {
      "method.request.path.proxy"        = false
      "method.request.querystring.unity" = true
  }

  request_validator_id = aws_api_gateway_request_validator.validator.id
}


// Integrate with SQS
resource "aws_api_gateway_integration" "apigw_int" {
  rest_api_id             = aws_api_gateway_rest_api.apigw.id
  resource_id             = aws_api_gateway_resource.resource.id
  http_method             = aws_api_gateway_method.method.http_method
  type                    = "AWS"
  integration_http_method = "POST"
  credentials             = aws_iam_role.apigw_sqs.arn
  uri                     = "arn:aws:apigateway:${var.region}:sqs:path/${aws_sqs_queue.queue.name}"

  request_parameters = {
    "integration.request.header.Content-Type" = "'application/x-www-form-urlencoded'"
  }

// Request template for passing method to SQS messages
  request_templates = {
    "application/json" = <<EOF
Action=SendMessage&MessageBody={
  "method": "$context.httpMethod",
  "body-json" : $input.json('$'),
  "queryParams": {
    #foreach($param in $input.params().querystring.keySet())
    "$param": "$util.escapeJavaScript($input.params().querystring.get($param))" #if($foreach.hasNext),#end
  #end
  },
  "pathParams": {
    #foreach($param in $input.params().path.keySet())
    "$param": "$util.escapeJavaScript($input.params().path.get($param))" #if($foreach.hasNext),#end
    #end
  }
}"
EOF
  }

  depends_on = [
    aws_iam_role_policy_attachment.apigw_exec_role
  ]
}


// Integrate with Lambda
resource "aws_api_gateway_integration" "integration" {
  rest_api_id             = aws_api_gateway_rest_api.apigw.id
  resource_id             = aws_api_gateway_resource.resource.id
  http_method             = aws_api_gateway_method.method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.lambda.invoke_arn
}

resource "aws_lambda_permission" "apigw_lambda" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "arn:aws:execute-api:${var.region}:${var.account_id}:${aws_api_gateway_rest_api.apigw.id}/*/${aws_api_gateway_method.method.http_method}${aws_api_gateway_resource.resource.path}"
}

resource "aws_lambda_function" "lambda" {
  filename      = "lambda.zip"
  function_name = "mylambda"
  role          = aws_iam_role.lambda_exec.arn
  handler       = "lambda.lambda_handler"
  runtime       = "python3.6"

  source_code_hash = filebase64sha256("lambda/lambda.zip")
}
