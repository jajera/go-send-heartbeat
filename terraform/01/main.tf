resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

resource "aws_iam_user" "example" {
  name = "go-user-${random_string.suffix.result}"
}

resource "aws_iam_access_key" "example" {
  user = aws_iam_user.example.name
}

resource "aws_sqs_queue" "example" {
  name                      = "sqs-${random_string.suffix.result}"
  delay_seconds             = 0
  max_message_size          = 262144
  message_retention_seconds = 1209600
  receive_wait_time_seconds = 0
}

resource "aws_iam_policy" "sqs" {
  name = "sqs-send-heartbeat-${random_string.suffix.result}"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sqs:SendMessage"
        ]
        Resource = [
          "arn:aws:sqs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${aws_sqs_queue.example.name}"
        ]
      }
    ]
  })
}

resource "aws_iam_user_policy_attachment" "sqs" {
  user       = aws_iam_user.example.name
  policy_arn = aws_iam_policy.sqs.arn
}

resource "null_resource" "example" {
  triggers = {
    always_run = "${timestamp()}"
  }

  provisioner "local-exec" {
    command = <<-EOT
      echo "#!/bin/bash" > terraform.tmp
      echo "export AWS_ACCESS_KEY_ID=${aws_iam_access_key.example.id}" >> terraform.tmp
      echo "export AWS_SECRET_ACCESS_KEY=${aws_iam_access_key.example.secret}" >> terraform.tmp
      echo "export AWS_REGION=${data.aws_region.current.name}" >> terraform.tmp
      chmod +x terraform.tmp
    EOT
  }

  provisioner "local-exec" {
    when    = destroy
    command = <<-EOT
      rm -f terraform.tmp
    EOT
  }
}

output "aws_sqs_queue_url" {
  value = aws_sqs_queue.example.url
}

output "suffix" {
  value = random_string.suffix.result
}
