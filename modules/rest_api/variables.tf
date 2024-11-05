variable "vpc_id" {
  type = string
}

variable "authenticator_lambda_arn" {
  type = string
}

variable "authenticator_lambda_name" {
  type = string
}

variable "api_name" {
  description = "API Name"
  type        = string
  default     = "authenticator"
}

variable "vpc_name" {
  description = "VPC Name"
  type        = string
  default     = "eks-fiap-vpc"
}

variable "profile" {
  description = "AWS profile name"
  type        = string
  default     = "default"
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "user_pool_name" {
  type        = string
  description = "Cognito user pool name"
  default     = "bmb_users_pool"
}

variable "elb_map" {
  type = map(string)
  default = {
    "payment" = "local.domain.com",
    "kitchen" = "local.domain.com"
    "log"     = "local.domain.com"
  }
}

variable "elb_map_x" {
  type = map(object({
    dns_name = string
    auth     = bool
    elb_arn  = string
  }))
  default = {
    payment = {
      dns_name = "local.domain.com"
      auth     = true
      elb_arn  = "arn:aws:elasticloadbalancing:us-east-1::loadbalancer/app/eks-payment-elb/1234567890123456"
    }
    kitchen = {
      dns_name = "local.domain.com"
      auth     = true
      elb_arn  = "arn:aws:elasticloadbalancing:us-east-1::loadbalancer/app/eks-kitchen-elb/1234567890123456"
    }
    log = {
      dns_name = "local.domain.com"
      auth     = false
      elb_arn  = "arn:aws:elasticloadbalancing:us-east-1::loadbalancer/app/eks-log-elb/1234567890123456"
    }
  }
}
