data "archive_file" "lambda_with_dependencies" {
  source_dir  = "lambda/"
  output_path = "lambda/lambda.zip"
  type        = "zip"
}

resource "aws_lambda_function" "lambda_sqs" {
  function_name    = "lambda_sqs"
  handler          = "handler.lambda_handler"
  role             = aws_iam_role.lambda_exec.arn
  runtime          = "python3.7"

  filename         = data.archive_file.lambda_with_dependencies.output_path
  source_code_hash = data.archive_file.lambda_with_dependencies.output_base64sha256

  timeout          = 30
  memory_size      = 128

  depends_on = [
    aws_iam_role_policy_attachment.lambda_role_policy
  ]
}

resource "aws_lambda_permission" "allows_sqs_trigger_lambda" {
  statement_id  = "AllowExecutionFromSQS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_sqs.function_name
  principal     = "sqs.amazonaws.com"
  source_arn    = aws_sqs_queue.queue.arn
}

resource "aws_lambda_event_source_mapping" "event_mapping" {
  batch_size       = 1
  event_source_arn =  aws_sqs_queue.queue.arn
  enabled          = true
  function_name    =  aws_lambda_function.lambda_sqs.arn
}