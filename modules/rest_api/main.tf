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
  for_each    = var.elb_map
  rest_api_id = aws_api_gateway_rest_api.api_gtw.id
  resource_id = aws_api_gateway_resource.proxy[each.key].id
  http_method = "ANY"

  authorization = each.value.auth ? "CUSTOM" : "NONE"

  authorizer_id = each.value.auth ? aws_api_gateway_authorizer.cpf_auth.id : null
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
  uri                     = "http://${each.value.dns_name}/{proxy}"
  integration_http_method = "ANY"
  connection_type         = "VPC_LINK"
  connection_id           = aws_api_gateway_vpc_link.vpc_link[each.key].id

  timeout_milliseconds = 29000
  request_parameters = {
    "integration.request.path.proxy"         = "method.request.path.proxy"
    "integration.request.header.accessToken" = "context.authorizer.accessToken"
  }
}

resource "aws_api_gateway_authorizer" "cpf_auth" {
  rest_api_id                      = aws_api_gateway_rest_api.api_gtw.id
  name                             = "cpf_authorizer"
  type                             = "REQUEST"
  authorizer_uri                   = var.authenticator_lambda_arn
  identity_source                  = "method.request.header.cpf"
  authorizer_result_ttl_in_seconds = 10
}

resource "aws_api_gateway_vpc_link" "vpc_link" {
  for_each    = var.elb_map
  name        = "${each.key}-vpc_link"
  target_arns = [each.value.elb_arn]
}

resource "aws_api_gateway_deployment" "dev" {
  depends_on  = [aws_api_gateway_integration.integrations]
  rest_api_id = aws_api_gateway_rest_api.api_gtw.id
  # stage_name  = "dev"
  description =  sha1(jsonencode([
      aws_api_gateway_rest_api.api_gtw.body,
      aws_api_gateway_resource.payment_webhook_proxy
    ]))
  lifecycle {
    create_before_destroy = true
  }
  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_rest_api.api_gtw.body,
      aws_api_gateway_resource.payment_webhook_proxy
    ]))
  }
}

resource "aws_api_gateway_stage" "dev" {
  # count         = 0
  rest_api_id   = aws_api_gateway_rest_api.api_gtw.id
  stage_name    = "dev"#aws_api_gateway_deployment.dev.stage_name
  deployment_id = aws_api_gateway_deployment.dev.id

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gw_logs.arn
    format = jsonencode({
      requestId      = "$context.requestId"
      ip             = "$context.identity.sourceIp"
      caller         = "$context.identity.caller"
      user           = "$context.identity.user"
      requestTime    = "$context.requestTime"
      httpMethod     = "$context.httpMethod"
      resourcePath   = "$context.resourcePath"
      status         = "$context.status"
      protocol       = "$context.protocol"
      responseLength = "$context.responseLength"
    })
  }
}

resource "aws_cloudwatch_log_group" "api_gw_logs" {
  name              = "/aws/api-gateway/${var.api_name}"
  retention_in_days = 1
}

resource "aws_lambda_permission" "lambda_agw_invoke_permission" {
  action        = "lambda:InvokeFunction"
  function_name = var.authenticator_lambda_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.api_gtw.execution_arn}/*/*"
}


#### CONFIG CORS #####
resource "aws_api_gateway_method" "cors_options" {
  for_each      = var.elb_map
  rest_api_id   = aws_api_gateway_rest_api.api_gtw.id
  resource_id   = aws_api_gateway_resource.proxy[each.key].id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "cors_integration" {
  for_each    = var.elb_map
  rest_api_id = aws_api_gateway_rest_api.api_gtw.id
  resource_id = aws_api_gateway_resource.proxy[each.key].id
  http_method = aws_api_gateway_method.cors_options[each.key].http_method
  type        = "MOCK"

  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_method_response" "cors_method_response" {
  for_each    = var.elb_map
  rest_api_id = aws_api_gateway_rest_api.api_gtw.id
  resource_id = aws_api_gateway_resource.proxy[each.key].id
  http_method = aws_api_gateway_method.cors_options[each.key].http_method
  status_code = "200"

  response_models = {
    "application/json" = "Empty"
  }

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

resource "aws_api_gateway_integration_response" "cors_integration_response" {
  for_each = var.elb_map
  depends_on = [
    aws_api_gateway_method_response.cors_method_response["production"],
    aws_api_gateway_method_response.cors_method_response["orders"],
    aws_api_gateway_method_response.cors_method_response["payment"]
  ]
  rest_api_id = aws_api_gateway_rest_api.api_gtw.id
  resource_id = aws_api_gateway_resource.proxy[each.key].id
  http_method = aws_api_gateway_method.cors_options[each.key].http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token,X-Amz-User-Agent,Cpf'"
    "method.response.header.Access-Control-Allow-Methods" = "'GET,PUT,POST,PATCH,OPTIONS'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }
}

######### NO AUTH WEBHOOK ######

resource "aws_api_gateway_resource" "payment_webhook_resource" {
  depends_on = [
    aws_api_gateway_resource.resource["payment"],
  ]
  rest_api_id = aws_api_gateway_rest_api.api_gtw.id
  parent_id   = aws_api_gateway_resource.resource["payment"].id
  path_part   = "webhook"
}

resource "aws_api_gateway_resource" "payment_webhook_proxy" {
  rest_api_id = aws_api_gateway_rest_api.api_gtw.id
  parent_id   = aws_api_gateway_resource.payment_webhook_resource.id
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "payment_webhook_proxy_method" {
  rest_api_id = aws_api_gateway_rest_api.api_gtw.id
  resource_id = aws_api_gateway_resource.payment_webhook_proxy.id
  http_method = "POST"
  authorization = "NONE"
  request_parameters = {
    "method.request.path.proxy" = true
  }
}

resource "aws_api_gateway_integration" "payment_webhook_integrations" {
  rest_api_id             = aws_api_gateway_rest_api.api_gtw.id
  resource_id             = aws_api_gateway_resource.payment_webhook_proxy.id
  http_method             = aws_api_gateway_method.payment_webhook_proxy_method.http_method
  type                    = "HTTP_PROXY"
  uri                     = "http://${var.elb_map["payment"].dns_name}/api/notifications/{proxy}"
  integration_http_method = "POST"
  connection_type         = "VPC_LINK"
  connection_id           = aws_api_gateway_vpc_link.vpc_link["payment"].id

  timeout_milliseconds = 29000
  request_parameters = {
    "integration.request.path.proxy"         = "method.request.path.proxy"
  }
}