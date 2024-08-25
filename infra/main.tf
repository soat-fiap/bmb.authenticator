terraform {
  backend "remote" {
    organization = "FiapPostech-SOAT"
    workspaces {
      name = "bmb-authenticator"
    }
  }
}

data "aws_vpc" "vpc_sample" {
  filter {
    name   = "tag:Name"
    values = [var.vpc_name]
  }

  filter {
    name   = "tag:Terraform"
    values = ["true"]
  }
}

data "aws_subnets" "private_subnets" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.vpc_sample.id]
  }

  filter {
    name   = "tag:Terraform"
    values = ["true"]
  }

  filter {
    name   = "tag:kubernetes.io/role/internal-elb"
    values = ["1"]
  }
}

data "aws_lb" "eks_internal_elb" {
  name = var.nlb_name
}

data "aws_lb_listener" "nlb_listener" {
  load_balancer_arn = data.aws_lb.eks_internal_elb.arn
  port              = 80
}


data "aws_cognito_user_pools" "bmb_selected_user_pool" {
  name = var.user_pool_name
}

module "authenticator_lambda_function" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "~> 7.7.1"

  function_name = "bmb_authorizer"
  description   = "lambda used to authenticate users against cognito"
  handler       = "src/handlers/hello-from-lambda.handler"
  runtime       = "nodejs18.x"
  source_path   = "../app/cpf-policy-authorizer"

  attach_policy_json = true
  policy_json        = <<-EOT
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Sid": "LambdaTerraform",
          "Effect": "Allow",
          "Action": [
              "cognito-idp:AdminListGroupsForUser",
              "cognito-idp:AdminGetUser"
          ],
          "Resource": "${data.aws_cognito_user_pools.bmb_selected_user_pool.arns[0]}" 
        }
      ]
    }
  EOT

  environment_variables = {
    "ACCESS_TOKEN_SECRET"   = "my-secret"
    "ACCESS_TOKEN_ISSUER"   = "http://italo.com"
    "ACCESS_TOKEN_AUDIENCE" = "http://italo.com/client",
    "ACCESS_TOKEN_EXP"      = 300
    "USER_POOL_ID"          = data.aws_cognito_user_pools.bmb_selected_user_pool.ids[0],
    "REGION"                = var.region
  }

  tags = {
    Terraform = "true"
  }
}

module "authenticator_api" {
  source = "./modules/authenticator_agw"

  api_name         = var.api_name
  vpc_id           = data.aws_vpc.vpc_sample.id
  nlb_listener_arn = data.aws_lb_listener.nlb_listener.arn
  vpc_link_subnets = data.aws_subnets.private_subnets.ids
  # vpc_id                    = "dataaws_vpc.vpc_sample.id"
  # nlb_listener_arn          = "dataaws_lb_listener.nlb_listener.arn"
  # vpc_link_subnets          = ["dataaws_subnets.private_subnets.ids"]
  profile                   = var.profile
  region                    = var.region
  authenticator_lambda_arn  = module.authenticator_lambda_function.lambda_function_invoke_arn
  authenticator_lambda_name = module.authenticator_lambda_function.lambda_function_name
}
