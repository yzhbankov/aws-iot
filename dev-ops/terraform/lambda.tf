locals {
  kinesis-lambda = "${path.module}/../../apps/lambdas/kinesis"
  lambda_timeout = 60
}

# Users LAMBDA
resource "null_resource" "install_kinesis_lambda_dependencies" {
  provisioner "local-exec" {
    command = "cd ${local.kinesis-lambda} && npm install"
  }

  triggers = {
    always_run = timestamp()
  }
}

data "archive_file" "kinesis-lambda" {
  type        = "zip"
  source_dir  = local.kinesis-lambda
  output_path = "/tmp/kinesis-lambda.zip"

  depends_on = [null_resource.install_kinesis_lambda_dependencies]
}

resource "aws_lambda_function" "firehose_transform_lambda" {
  function_name    = "${terraform.workspace}-yz-kinesis-lambda"
  role             = aws_iam_role.lambda_execution_role.arn
  filename         = data.archive_file.kinesis-lambda.output_path
  handler          = "index.handler"
  source_code_hash = data.archive_file.kinesis-lambda.output_base64sha256
  runtime          = "nodejs18.x"
  timeout          = local.lambda_timeout

  environment {
    variables = {
      BUCKET_NAME = aws_s3_bucket.firehose_destination_bucket.bucket
    }
  }
}

# IAM Role for Lambda function
resource "aws_iam_role" "lambda_execution_role" {
  name = "lambda-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_policy" "custom_lambda_policy" {
  name = "CustomLambdaPolicy"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action   = ["lambda:*"],
        Effect   = "Allow",
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = "logs:CreateLogGroup",
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = "arn:aws:logs:*:*:log-group:/aws/lambda/*"
      }
    ]
  })
}

# Attach the custom policy to the Lambda execution role
resource "aws_iam_role_policy_attachment" "lambda_policy_attachment" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = aws_iam_policy.custom_lambda_policy.arn
}
