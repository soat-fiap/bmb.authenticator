# data "aws_vpc" "bmb_vpc" {
#   filter {
#     name   = "tag:Name"
#     values = [var.vpc_name]
#   }

#   filter {
#     name   = "tag:Terraform"
#     values = ["true"]
#   }
# }

# data "aws_subnets" "private_subnets" {
#   filter {
#     name   = "vpc-id"
#     values = [data.aws_vpc.bmb_vpc.id]
#   }

#   filter {
#     name   = "tag:Terraform"
#     values = ["true"]
#   }

#   filter {
#     name   = "tag:kubernetes.io/role/internal-elb"
#     values = ["1"]
#   }
# }

data "aws_lb" "eks_payment_elb" {
  tags = {
    "kubernetes.io/service-name" = "fiap-payment/api-internal"
  }
}

data "aws_lb" "eks_kitchen_elb" {
  tags = {
    "kubernetes.io/service-name" = "fiap-production/api-internal"
  }
}

data "aws_lb" "load_balancers" {
  for_each = var.services
  tags = {
    "kubernetes.io/service-name" = "${each.value.namespace}/api-internal"
  }
}

# data "aws_lb" "service_elbs" {
#   for_each = var.services
#   tags = {
#     "kubernetes.io/service-name" = "${each.value}/api-internal"
#   }
# }


# data "aws_lb_listener" "payment_nlb_listener" {
#   load_balancer_arn = data.aws_lb.eks_payment_elb.arn
#   port              = 80
# }


# data "aws_lb_listener" "kitchen_nlb_listener" {
#   load_balancer_arn = data.aws_lb.eks_kitchen_elb.arn
#   port              = 80
# }


data "aws_cognito_user_pools" "bmb_selected_user_pool" {
  name = var.user_pool_name
}

data "archive_file" "lambda_zip" {
  type             = "zip"
  source_dir       = "${path.module}/app/cpf-policy-authorizer"
  output_file_mode = "0666"
  output_path      = "${path.module}/files/lambda.zip"
}
