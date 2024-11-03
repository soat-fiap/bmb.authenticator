resource "aws_api_gateway_rest_api" "api_gtw" {
  name        = var.api_name
  description = "BMB REST API Gateway"
  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_resource" "resource" {
  for_each    = var.elb_map
  rest_api_id = aws_api_gateway_rest_api.api_gtw.id
  parent_id   = aws_api_gateway_rest_api.api_gtw.root_resource_id
  path_part   = each.key
}

resource "aws_api_gateway_resource" "proxy" {
  for_each    = var.elb_map
  rest_api_id = aws_api_gateway_rest_api.api_gtw.id
  parent_id   = aws_api_gateway_resource.resource[each.key].id
  path_part   = "{proxy+}"
}

//https://gist.github.com/mendhak/8303d60cbfe8c9bf1905def3ccdb2176
resource "aws_api_gateway_method" "proxy_method" {
  for_each      = var.elb_map
  rest_api_id   = aws_api_gateway_rest_api.api_gtw.id
  resource_id   = aws_api_gateway_resource.proxy[each.key].id
  http_method   = "ANY"
  authorization = "NONE"
  # authorizer_id = aws_api_gateway_authorizer.example.id
  request_parameters = {
    "method.request.path.proxy" = true
  }
}

resource "aws_api_gateway_integration" "integrations" {
  for_each                = var.elb_map
  rest_api_id             = aws_api_gateway_rest_api.api_gtw.id
  resource_id             = aws_api_gateway_resource.proxy[each.key].id
  http_method             = aws_api_gateway_method.proxy_method[each.key].http_method
  type                    = "HTTP_PROXY"
  uri                     = "http://${each.value}/{proxy}"
  integration_http_method = "ANY"
  connection_type         = "INTERNET"

  # cache_key_parameters = ["method.request.path.proxy"]
  timeout_milliseconds = 29000
  request_parameters = {
    # "integration.request.header.accessToken" = "method.request.header.Authorization"
    "integration.request.path.proxy" = "method.request.path.proxy"
  }

}

# resource "aws_api_gateway_integration" "payment_proxy_integration" {
#   for_each               = var.elb_map
#   rest_api_id             = aws_api_gateway_rest_api.api_gtw.id
#   resource_id            = aws_api_gateway_resource.proxy[each.key].id
#   http_method            = aws_api_gateway_method.proxy_method[each.key].http_method
#   type                    = "HTTP_PROXY"
#   uri                    = "http://${each.value}/{proxy}"
#   integration_http_method = "ANY"
#   connection_type         = "VPC_LINK"
#   connection_id           = aws_api_gateway_vpc_link.example.id

#   # cache_key_parameters = ["method.request.path.proxy"]
#   timeout_milliseconds = 29000
#   request_parameters = {
#     # "integration.request.header.accessToken" = "method.request.header.Authorization"
#     "integration.request.path.proxy" = "method.request.path.proxy"
#   }


#   # integration_response {
#   #   status_code = "200"
#   #   response_parameters = {
#   #     "method.response.header.accessToken" = "integration.response.header.accessToken"
#   #   }
#   # }
# }

# resource "aws_api_gateway_authorizer" "example" {
#   rest_api_id                      = aws_api_gateway_rest_api.api_gtw.id
#   name                             = "cpf_authorizer"
#   type                             = "REQUEST"
#   authorizer_uri                   = var.authenticator_lambda_arn
#   identity_source                  = "method.request.header.Authorization"
#   authorizer_result_ttl_in_seconds = 0
# }

# resource "aws_api_gateway_vpc_link" "example" {
#   name        = "${var.api_name}-vpc_link"
#   target_arns = [var.payment_nlb_listener_arn]
# }

# resource "aws_api_gateway_deployment" "example" {
#   depends_on  = [aws_api_gateway_integration.payment_proxy_integration]
#   rest_api_id = aws_api_gateway_rest_api.api_gtw.id
#   stage_name  = "dev"
# }

# resource "aws_api_gateway_stage" "example" {
#   count         = 0
#   rest_api_id   = aws_api_gateway_rest_api.api_gtw.id
#   stage_name    = aws_api_gateway_deployment.example.stage_name
#   deployment_id = aws_api_gateway_deployment.example.id

#   access_log_settings {
#     destination_arn = aws_cloudwatch_log_group.api_gw_logs.arn
#     format = jsonencode({
#       requestId      = "$context.requestId"
#       ip             = "$context.identity.sourceIp"
#       caller         = "$context.identity.caller"
#       user           = "$context.identity.user"
#       requestTime    = "$context.requestTime"
#       httpMethod     = "$context.httpMethod"
#       resourcePath   = "$context.resourcePath"
#       status         = "$context.status"
#       protocol       = "$context.protocol"
#       responseLength = "$context.responseLength"
#     })
#   }
# }

resource "aws_cloudwatch_log_group" "api_gw_logs" {
  name              = "/aws/api-gateway/${var.api_name}"
  retention_in_days = 1
}

# resource "aws_lambda_permission" "lambda_agw_invoke_permission" {
#   action        = "lambda:InvokeFunction"
#   function_name = var.authenticator_lambda_name
#   principal     = "apigateway.amazonaws.com"
#   source_arn    = "${aws_api_gateway_rest_api.api_gtw.execution_arn}/*/*"
# }

# resource "aws_security_group" "api_gateway_security_group" {
#   name        = "bmb-vpclink-sg"
#   description = "API Gateway security group"
#   vpc_id      = var.vpc_id

#   ingress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   tags = {
#     Terraform = "true"
#   }
# }
