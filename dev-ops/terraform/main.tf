resource "aws_s3_bucket" "firehose_destination_bucket" {
  bucket = "${terraform.workspace}-yz-iot-destination"
}

# Kinesis Firehose delivery stream
resource "aws_kinesis_firehose_delivery_stream" "firehose_stream" {
  name        = "${terraform.workspace}-yz-firehose-stream"
  destination = "extended_s3"

  extended_s3_configuration {
    role_arn           = aws_iam_role.firehose_delivery_role.arn
    bucket_arn         = aws_s3_bucket.firehose_destination_bucket.arn
    buffering_size     = 5
    buffering_interval = 300
    compression_format = "GZIP"

    cloudwatch_logging_options {
      enabled         = true
      log_group_name  = "/aws/kinesisfirehose/firehose-stream"
      log_stream_name = "S3Delivery"
    }

    processing_configuration {
      enabled = true

      processors {
        type = "Lambda"

        parameters {
          parameter_name  = "LambdaArn"
          parameter_value = aws_lambda_function.firehose_transform_lambda.arn
        }
      }
    }
  }
}

# IAM Role for Kinesis Firehose to access S3 and Lambda
resource "aws_iam_role" "firehose_delivery_role" {
  name = "${terraform.workspace}-yz-firehose-delivery-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "firehose.amazonaws.com"
      }
    }]
  })

  # Inline policy to add S3 and Lambda permissions
  inline_policy {
    name = "firehose-s3-lambda-policy"

    policy = jsonencode({
      Version = "2012-10-17",
      Statement = [
        {
          Sid    = "",
          Effect = "Allow",
          Action = [
            "s3:AbortMultipartUpload",
            "s3:GetBucketLocation",
            "s3:GetObject",
            "s3:ListBucket",
            "s3:ListBucketMultipartUploads",
            "s3:PutObject"
          ],
          Resource = [
            aws_s3_bucket.firehose_destination_bucket.arn,
            "${aws_s3_bucket.firehose_destination_bucket.arn}/*"
          ]
        },
        {
          Sid    = "",
          Effect = "Allow",
          Action = [
            "lambda:InvokeFunction",
            "lambda:GetFunctionConfiguration"
          ],
          Resource = "${aws_lambda_function.firehose_transform_lambda.arn}:$LATEST"
        }
      ]
    })
  }
}

# IoT Core Rule
resource "aws_iot_topic_rule" "iot_to_firehose_rule" {
  name        = "IoTToFirehoseRule"
  sql         = "SELECT * FROM '#'"
  sql_version = "2016-03-23"
  enabled     = true

  firehose {
    delivery_stream_name = aws_kinesis_firehose_delivery_stream.firehose_stream.name
    role_arn             = aws_iam_role.iot_kinesis_role.arn
    batch_mode           = true
  }
}

# IAM Role for IoT Rule to access Kinesis Firehose
resource "aws_iam_role" "iot_kinesis_role" {
  name = "${terraform.workspace}-yz-iot-kinesis-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "iot.amazonaws.com"
      }
    }]
  })
}

# Policy attachment for IoT Rule to access Firehose
resource "aws_iam_role_policy_attachment" "iot_kinesis_policy" {
  role       = aws_iam_role.iot_kinesis_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonKinesisFirehoseFullAccess"
}

resource "aws_iam_role_policy_attachment" "firehose_lambda_policy" {
  role       = aws_iam_role.firehose_delivery_role.name
  policy_arn = aws_iam_policy.custom_lambda_policy.arn
}
