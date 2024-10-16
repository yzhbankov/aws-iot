output "aws_region" {
  value = var.AWS_REGION
}

output "iot_certificate_pem" {
  value     = aws_iot_certificate.iot_certificate.certificate_pem
  sensitive = true
}

output "iot_certificate_arn" {
  value     = aws_iot_certificate.iot_certificate.arn
  sensitive = true
}

output "iot_private_key" {
  value     = aws_iot_certificate.iot_certificate.private_key
  sensitive = true
}

output "iot_public_key" {
  value     = aws_iot_certificate.iot_certificate.public_key
  sensitive = true
}

output "api_gateway_base_url" {
  value = aws_api_gateway_deployment.deployment.invoke_url
}

output "dynamodb" {
  value = aws_dynamodb_table.iot_things_table.name
}

