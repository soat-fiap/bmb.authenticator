module "api_gateway" {
  source  = "terraform-aws-modules/apigateway-v2/aws"
  version = "~> 5.1.2"

  name          = var.api_name
  description   = "BMB HTTP API Gateway"
  protocol_type = "HTTP"

  cors_configuration = {
    allow_headers = ["content-type", "x-amz-date", "authorization", "x-api-key", "x-amz-security-token", "x-amz-user-agent"]
    allow_methods = ["*"]
    allow_origins = ["*"]
  }

  # Access logs
  stage_access_log_settings = {
    create_log_group            = true
    log_group_retention_in_days = 1
    format = jsonencode({
      context = {
        domainName              = "$context.domainName"
        integrationErrorMessage = "$context.integrationErrorMessage"
        protocol                = "$context.protocol"
        requestId               = "$context.requestId"
        requestTime             = "$context.requestTime"
        responseLength          = "$context.responseLength"
        routeKey                = "$context.routeKey"
        stage                   = "$context.stage"
        status                  = "$context.status"
        error = {
          message      = "$context.error.message"
          responseType = "$context.error.responseType"
        }
        identity = {
          sourceIP = "$context.identity.sourceIp"
        }
        integration = {
          error             = "$context.integration.error"
          integrationStatus = "$context.integration.integrationStatus",
          accessToken       = "$context.authorizer.accessToken",
        }
      }
    })
  }

  create_domain_name = false

  authorizers = {
    "cpf-auth" = {
      authorizer_type  = "REQUEST"
      identity_sources = ["$request.header.Authorization"]
      name             = "cpf-auth"

      # authorizer_credentials_arn
      authorizer_payload_format_version = "2.0"
      enable_simple_responses           = false
      authorizer_uri                    = var.authenticator_lambda_arn
    }
  }

  # Routes & Integration(s)
  routes = {
    # "ANY /{proxy+}" = {
    #   integration = {
    #     connection_type = "VPC_LINK"
    #     type            = "HTTP_PROXY"
    #     uri             = var.nlb_listener_arn
    #     method          = "ANY"
    #     vpc_link_key    = "bmb-vpc"
    #   }
    # }

    "GET /{proxy+}" = {
      authorization_type = "CUSTOM"
      authorizer_id      = aws_apigatewayv2_authorizer.external.id
      integration = {
        type   = "HTTP_PROXY"
        uri    = "https://nginx.org/en"
        method = "GET"

        response_parameters = [
          {
            status_code = 200
            mappings = {
              "append:header.accessToken" = "$context.authorizer.accessToken"
            }
          }
        ]
      }
    }

    # "GET /hello" = {
    #   integration = {
    #     uri                    = var.authenticator_lambda_arn
    #     payload_format_version = "2.0"
    #     timeout_milliseconds   = 1200
    #     description            = "connect with lambda"
    #     integration_type       = "AWS_PROXY"
    #   }
    # }
  }

  # VPC Link
  # vpc_links = {
  #   bmb-vpc = {
  #     name               = "${var.api_name}-vpc_link"
  #     security_group_ids = [module.api_gateway_security_group.security_group_id]
  #     subnet_ids         = var.vpc_link_subnets
  #   }
  # }

  tags = {
    Terraform = "true"
  }
}

resource "random_uuid" "lambda_permission_statement" {

}

resource "aws_lambda_permission" "lambda_agw_invoke_permission" {
  action        = "lambda:InvokeFunction"
  statement_id  = random_uuid.lambda_permission_statement.result
  function_name = var.authenticator_lambda_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${module.api_gateway.api_execution_arn}/authorizers/${aws_apigatewayv2_authorizer.external.id}"
}

# module "api_gateway_security_group" {
#   source  = "terraform-aws-modules/security-group/aws"
#   version = "~> 5.1.2"

#   name        = "bmb-vpclink-sg"
#   description = "API Gateway group for example usage"
#   vpc_id      = var.vpc_id

#   ingress_cidr_blocks = ["0.0.0.0/0"]
#   ingress_rules       = ["all-all"]

#   egress_rules = ["all-all"]

#   tags = {
#     Terraform = "true"
#     Created   = timestamp()
#   }
# }


resource "aws_apigatewayv2_authorizer" "external" {
  api_id          = module.api_gateway.api_id
  authorizer_type = "REQUEST"
  name                              = "cpf_authorizer"
  authorizer_payload_format_version = "2.0"
  authorizer_result_ttl_in_seconds  = 0
  enable_simple_responses           = false
  authorizer_uri                    = var.authenticator_lambda_arn
}