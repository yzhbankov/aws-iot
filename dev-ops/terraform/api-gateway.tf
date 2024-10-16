resource "aws_api_gateway_rest_api" "iot-api" {
  name        = "iot-portal-api"
  description = "IoT Portal API Gateway"
  body = templatefile("${path.module}/../../apps/api-gateway/api.yaml",
    {
      aws_region           = var.AWS_REGION
      iot_thing_lambda_arn = aws_lambda_function.iot-thing-lambda.arn
      domain_url           = ""
    }
  )

  endpoint_configuration {
    types = ["REGIONAL"]
  }

  tags = {
    Name = "iot-api-gateway"
  }
}

resource "aws_api_gateway_deployment" "deployment" {
  rest_api_id = aws_api_gateway_rest_api.iot-api.id
  stage_name  = "prod"
}

resource "aws_lambda_permission" "api-gateway-invoke-iot-thing-lambda" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.iot-thing-lambda.function_name
  principal     = "apigateway.amazonaws.com"

  # The /*/* portion grants access from any method on any resource
  # within the specified API Gateway.
  source_arn = "${aws_api_gateway_rest_api.iot-api.execution_arn}/*/*"
}
