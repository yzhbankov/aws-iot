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

  inline_policy {
    name = "${terraform.workspace}-yz-firehose-policy"

    policy = jsonencode({
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Sid" : "",
          "Effect" : "Allow",
          "Action" : [
            "glue:GetTable",
            "glue:GetTableVersion",
            "glue:GetTableVersions"
          ],
          "Resource" : [
            "arn:aws:glue:us-east-1:968600019916:catalog",
            "arn:aws:glue:us-east-1:968600019916:database/%FIREHOSE_POLICY_TEMPLATE_PLACEHOLDER%",
            "arn:aws:glue:us-east-1:968600019916:table/%FIREHOSE_POLICY_TEMPLATE_PLACEHOLDER%/%FIREHOSE_POLICY_TEMPLATE_PLACEHOLDER%"
          ]
        },
        {
          "Sid" : "",
          "Effect" : "Allow",
          "Action" : [
            "kafka:GetBootstrapBrokers",
            "kafka:DescribeCluster",
            "kafka:DescribeClusterV2",
            "kafka-cluster:Connect"
          ],
          "Resource" : "arn:aws:kafka:us-east-1:968600019916:cluster/%FIREHOSE_POLICY_TEMPLATE_PLACEHOLDER%/%FIREHOSE_POLICY_TEMPLATE_PLACEHOLDER%"
        },
        {
          "Sid" : "",
          "Effect" : "Allow",
          "Action" : [
            "kafka-cluster:DescribeTopic",
            "kafka-cluster:DescribeTopicDynamicConfiguration",
            "kafka-cluster:ReadData"
          ],
          "Resource" : "arn:aws:kafka:us-east-1:968600019916:topic/%FIREHOSE_POLICY_TEMPLATE_PLACEHOLDER%/%FIREHOSE_POLICY_TEMPLATE_PLACEHOLDER%/%FIREHOSE_POLICY_TEMPLATE_PLACEHOLDER%"
        },
        {
          "Sid" : "",
          "Effect" : "Allow",
          "Action" : [
            "kafka-cluster:DescribeGroup"
          ],
          "Resource" : "arn:aws:kafka:us-east-1:968600019916:group/%FIREHOSE_POLICY_TEMPLATE_PLACEHOLDER%/%FIREHOSE_POLICY_TEMPLATE_PLACEHOLDER%/*"
        },
        {
          "Sid" : "",
          "Effect" : "Allow",
          "Action" : [
            "s3:AbortMultipartUpload",
            "s3:GetBucketLocation",
            "s3:GetObject",
            "s3:ListBucket",
            "s3:ListBucketMultipartUploads",
            "s3:PutObject"
          ],
          "Resource" : [
            aws_s3_bucket.firehose_destination_bucket.arn,
            "${aws_s3_bucket.firehose_destination_bucket.arn}/*"
          ]
        },
        {
          "Sid" : "",
          "Effect" : "Allow",
          "Action" : [
            "lambda:InvokeFunction",
            "lambda:GetFunctionConfiguration"
          ],
          "Resource" : "${aws_lambda_function.firehose_transform_lambda.arn}:$LATEST"
        },
        {
          "Effect" : "Allow",
          "Action" : [
            "kms:GenerateDataKey",
            "kms:Decrypt"
          ],
          "Resource" : [
            "arn:aws:kms:us-east-1:968600019916:key/%FIREHOSE_POLICY_TEMPLATE_PLACEHOLDER%"
          ],
          "Condition" : {
            "StringEquals" : {
              "kms:ViaService" : "s3.us-east-1.amazonaws.com"
            },
            "StringLike" : {
              "kms:EncryptionContext:aws:s3:arn" : [
                "arn:aws:s3:::%FIREHOSE_POLICY_TEMPLATE_PLACEHOLDER%/*",
                "arn:aws:s3:::%FIREHOSE_POLICY_TEMPLATE_PLACEHOLDER%"
              ]
            }
          }
        },
        {
          "Sid" : "",
          "Effect" : "Allow",
          "Action" : [
            "logs:PutLogEvents"
          ],
          "Resource" : [
            "arn:aws:logs:us-east-1:968600019916:log-group:/aws/kinesisfirehose/PUT-S3-t8RP4:log-stream:*",
            "arn:aws:logs:us-east-1:968600019916:log-group:%FIREHOSE_POLICY_TEMPLATE_PLACEHOLDER%:log-stream:*"
          ]
        },
        {
          "Sid" : "",
          "Effect" : "Allow",
          "Action" : [
            "kinesis:DescribeStream",
            "kinesis:GetShardIterator",
            "kinesis:GetRecords",
            "kinesis:ListShards"
          ],
          "Resource" : "arn:aws:kinesis:us-east-1:968600019916:stream/%FIREHOSE_POLICY_TEMPLATE_PLACEHOLDER%"
        },
        {
          "Effect" : "Allow",
          "Action" : [
            "kms:Decrypt"
          ],
          "Resource" : [
            "arn:aws:kms:us-east-1:968600019916:key/%FIREHOSE_POLICY_TEMPLATE_PLACEHOLDER%"
          ],
          "Condition" : {
            "StringEquals" : {
              "kms:ViaService" : "kinesis.us-east-1.amazonaws.com"
            },
            "StringLike" : {
              "kms:EncryptionContext:aws:kinesis:arn" : "arn:aws:kinesis:us-east-1:968600019916:stream/%FIREHOSE_POLICY_TEMPLATE_PLACEHOLDER%"
            }
          }
        }
      ]
    })
  }
}

# IoT Core Rule
resource "aws_iot_topic_rule" "iot_to_firehose_rule" {
  name        = "IoTToFirehoseRule"
  sql         = "SELECT * FROM 'topic_2'"
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
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "firehose:PutRecord",
          "firehose:PutRecordBatch"
        ],
        "Resource" : aws_kinesis_firehose_delivery_stream.firehose_stream.arn
      }
    ]
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

# IoT Thing
resource "aws_iot_thing" "iot_thing" {
  name = "${terraform.workspace}-yz-iot-thing"
}

# IoT Thing Certificate
resource "aws_iot_certificate" "iot_certificate" {
  active = true
}

# Attach Certificate to the IoT Thing
resource "aws_iot_thing_principal_attachment" "iot_thing_certificate_attachment" {
  thing     = aws_iot_thing.iot_thing.name
  principal = aws_iot_certificate.iot_certificate.arn
}

# IoT Policy
resource "aws_iot_policy" "iot_policy" {
  name = "${terraform.workspace}-yz-iot-policy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      "Effect" : "Allow",
      "Action" : [
        "iot:Connect",
        "iot:Publish",
        "iot:Subscribe",
        "iot:Receive"
      ],
      "Resource" : "*"
    }]
  })
}

# Attach IoT Policy to Certificate
resource "aws_iot_policy_attachment" "iot_policy_attachment" {
  policy = aws_iot_policy.iot_policy.name
  target = aws_iot_certificate.iot_certificate.arn
}

# Upload IoT certificate to S3
resource "aws_s3_object" "iot_certificate" {
  bucket  = aws_s3_bucket.firehose_destination_bucket.bucket
  key     = "certificates/iot_certificate.pem"
  content = aws_iot_certificate.iot_certificate.certificate_pem
}

# Upload IoT private key to S3
resource "aws_s3_object" "iot_private_key" {
  bucket  = aws_s3_bucket.firehose_destination_bucket.bucket
  key     = "certificates/iot_private_key.pem"
  content = aws_iot_certificate.iot_certificate.private_key
}
