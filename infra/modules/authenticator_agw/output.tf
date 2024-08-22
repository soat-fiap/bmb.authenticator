output "endpoint" {
  value = module.api_gateway.api_endpoint
}

output "execution_arn" {
  value = module.api_gateway.api_execution_arn
}
output "auth" {
  value = aws_apigatewayv2_authorizer.external
}
