locals {
  kinesis-lambda   = "${path.module}/../../apps/lambdas/kinesis"
  iot-thing-lambda = "${path.module}/../../apps/lambdas/iot-thing"
  lambda_timeout   = 60
}

# Kinesis Lambda Function
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
  function_name    = "${terraform.workspace}-kinesis-lambda-yz"
  role             = aws_iam_role.kinesis_transform_lambda_role.arn
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

resource "aws_iam_role" "kinesis_transform_lambda_role" {
  name = "kinesis_transform_lambda_role_yz"

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
        Effect   = "Allow",
        Action   = "logs:CreateLogGroup",
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

resource "aws_iam_role_policy_attachment" "lambda_policy_attachment" {
  role       = aws_iam_role.kinesis_transform_lambda_role.name
  policy_arn = aws_iam_policy.custom_lambda_policy.arn
}

resource "aws_iam_role_policy_attachment" "kinesis_lambda_dynamodb_role_policy" {
  role       = aws_iam_role.kinesis_transform_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"
}

# API Lambda Function
resource "null_resource" "install_iot_thing_dependencies" {
  provisioner "local-exec" {
    command = "cd ${local.iot-thing-lambda} && npm install"
  }

  triggers = {
    always_run = timestamp()
  }
}

data "archive_file" "iot-thing-lambda" {
  type        = "zip"
  source_dir  = local.iot-thing-lambda
  output_path = "/tmp/iot-thing-lambda.zip"

  depends_on = [null_resource.install_iot_thing_dependencies]
}

resource "aws_lambda_function" "iot-thing-lambda" {
  function_name    = "${terraform.workspace}-iot-thing-lambda-yz"
  role             = aws_iam_role.api_lambda_role.arn
  filename         = data.archive_file.iot-thing-lambda.output_path
  handler          = "index.handler"
  source_code_hash = data.archive_file.iot-thing-lambda.output_base64sha256
  runtime          = "nodejs20.x"
  timeout          = local.lambda_timeout

  environment {
    variables = {
      ENVIRONMENT = terraform.workspace
    }
  }
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "api_lambda_role" {
  name               = "${terraform.workspace}_api_lambda_role_yz"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy_attachment" "lambda_dynamodb_role_policy" {
  role       = aws_iam_role.api_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"
}

resource "aws_iam_role_policy_attachment" "lambda_basic_execution_role_policy" {
  role       = aws_iam_role.api_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "lambda_logs_role_policy" {
  role       = aws_iam_role.api_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
}
