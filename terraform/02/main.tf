locals {
  suffix = data.terraform_remote_state.state1.outputs.suffix
}

resource "aws_iam_role" "lambda" {
  name = "sqs-send-heartbeat-${local.suffix}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

data "aws_sqs_queue" "example" {
  name = "sqs-${local.suffix}"
}

resource "aws_iam_role_policy" "lambda" {
  name = "sqs-send-heartbeat-${local.suffix}"
  role = aws_iam_role.lambda.id
  policy = jsonencode({
    "Statement" : [
      {
        "Action" : [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        "Effect" : "Allow",
        "Resource" : "arn:aws:logs:*:*:*"
      },
      {
        "Action" : [
          "sqs:SendMessage"
        ],
        "Effect" : "Allow",
        "Resource" : data.aws_sqs_queue.example.arn
      }
    ]
  })
}

resource "null_resource" "example" {
  provisioner "local-exec" {
    when    = destroy
    command = <<-EOT
      rm -rf ./external
    EOT
  }
}

resource "aws_lambda_function" "example" {
  filename         = "${path.module}/external/bootstrap.zip"
  function_name    = "sqs-send-heartbeat-${local.suffix}"
  role             = aws_iam_role.lambda.arn
  architectures    = ["arm64"]
  handler          = "bootstrap"
  source_code_hash = filebase64sha256("${path.module}/external/bootstrap.zip")
  runtime          = "provided.al2023"
  environment {
    variables = {
      HEARTBEAT_QUEUE_URL = data.aws_sqs_queue.example.url
      HEARTBEAT_RUN_ONCE  = true
    }
  }
}
