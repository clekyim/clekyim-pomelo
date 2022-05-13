// APIGW
resource "aws_iam_role" "apigw_sqs" {
  name = "apigw_sqs"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "apigateway.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

data "template_file" "apigw_policy" {
  template = file("policies/apigw.json")

  vars = {
    sqs_arn   = aws_sqs_queue.queue.arn
  }
}

resource "aws_iam_policy" "apigw_policy" {
  name = "apigw-sqs-cloudwatch-policy"
  policy = data.template_file.apigw_policy.rendered
}


resource "aws_iam_role_policy_attachment" "apigw_exec_role" {
  role       =  aws_iam_role.apigw_sqs.name
  policy_arn =  aws_iam_policy.apigw_policy.arn
}


// Lambda
resource "aws_iam_role" "lambda_exec" {
  name               = "lambda-execution"
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

data "template_file" "lambda_policy" {
  template = file("policies/lambda.json")

  vars = {
    sqs_arn   = aws_sqs_queue.queue.arn
  }
}

resource "aws_iam_policy" "lambda_sqs_policy" {
  name        = "lambda_policy"
  policy = data.template_file.lambda_policy.rendered
}

resource "aws_iam_role_policy_attachment" "lambda_role_policy" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.lambda_sqs_policy.arn
}
