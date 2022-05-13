locals {
  order_input_transformer = {
    input_paths = {
      order_id = "$.detail.order_id"
    }
    input_template = <<EOF
    {
      "id": <order_id>
    }
    EOF
  }
}

module "eventbridge" {
  source = "terraform-aws-modules/eventbridge/aws"

  bus_name = "chayakorn-bus"

  attach_sqs_policy = true          //Attach Death-letter queue
  attach_kinesis_policy = true      //Attach Kinesis 
  attach_cloudwatch_policy = true   ////Attach CloudWatch

  sqs_target_arns = [
    aws_sqs_queue.queue.arn,
    aws_sqs_queue.deadletter_queue.arn 
  ]
  
  kinesis_target_arns = [
      aws_kinesis_stream.order_stream.arn
  ]

  cloudwatch_target_arns = [
      aws_cloudwatch_log_group.this.arn
  ]

  rules = {
    //Set up EventBridge Rules to transform messages
    orders_create = {
      description = "Capture all created orders",
      event_pattern = jsonencode({
        "detail-type" : ["Order Create"],
        "source" : ["api.gateway.orders.create"]
      })
      enabled       = true
    }
  }

  targets = {
    orders_create = [
      {
        //Send message to Dead-letter queue
        name            = "send-orders-to-sqs-with-dlq"
        arn             = aws_sqs_queue.queue.arn
        dead_letter_arn = aws_sqs_queue.deadletter_queue.arn
        target_id       = "send-orders-to-sqs"
      },
      {
        //Send message to Kinesis
        name              = "send-orders-to-kinesis"
        arn               = aws_kinesis_stream.order_stream.arn
        dead_letter_arn   = aws_sqs_queue.deadletter_queue.arn
        input_transformer = local.order_input_transformer
        attach_role_arn   = true
      },
      {
        //Send message to Cloudwatch
        name = "log-orders-to-cloudwatch"
        arn  = aws_cloudwatch_log_group.this.arn
      }
    ]
  }

  tags = {
    Name = "chayakorn-bus"
  }
}

module "apigateway_put_events_to_eventbridge_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "~> 4.0"

  create_role = true

  role_name         = "apigateway-put-events-to-eventbridge"
  role_requires_mfa = false

  trusted_role_services = ["apigateway.amazonaws.com"]

  custom_role_policy_arns = [
    module.apigateway_put_events_to_eventbridge_policy.arn
  ]
}

module "apigateway_put_events_to_eventbridge_policy" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "~> 4.0"

  name        = "apigateway-put-events-to-eventbridge"
  description = "Allow PutEvents to EventBridge"

  policy = data.aws_iam_policy_document.apigateway_put_events_to_eventbridge_policy.json
}

data "aws_iam_policy_document" "apigateway_put_events_to_eventbridge_policy" {
  statement {
    sid       = "AllowPutEvents"
    actions   = ["events:PutEvents"]
    resources = [module.eventbridge.eventbridge_bus_arn]
  }

  depends_on = [module.eventbridge]
}
