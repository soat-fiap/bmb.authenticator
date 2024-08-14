terraform {
  backend "remote" {
    organization = "FiapPostech-SOAT"
    workspaces {
      name = "bmb-authenticator"
    }
  }
}

# data "external" "vpc_id" {
#   program = ["bash", "-c", "aws ec2 describe-vpcs --filters Name=tag:Name,Values=${var.vpc_name} Name=tag:Terraform,Values=true --region us-east-1 --query 'Vpcs[*].VpcId' --output text"]
# }

# data "external" "subnets" {
#   program = ["bash", "-c", "aws ec2 describe-subnets --region us-east-1 --filters Name=vpc-id,Values=${data.external.vpc_id} Name=tag:kubernetes.io/role/internal-elb,Values=1 --query 'Subnets[*].SubnetId' --output text"]
# }

# aws elbv2 describe-load-balancers  --names teste --query "LoadBalancers[*].LoadBalancerArn" --output text

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

module "authenticator_api" {
  source = "./modules/authenticator_agw"

  api_name         = var.api_name
  vpc_id           = data.aws_vpc.vpc_sample.id
  nlb_listener_arn = data.aws_lb_listener.nlb_listener.arn
  vpc_link_subnets = data.aws_subnets.private_subnets.ids
  profile          = var.profile
  region           = var.region
}
