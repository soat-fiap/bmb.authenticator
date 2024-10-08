variable "vpc_id" {
  type = string
}

variable "vpc_link_subnets" {
  type = list(string)
}

variable "nlb_listener_arn" {
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

variable "nlb_name" {
  type    = string
  default = "bmb-nlb-controller"
}

variable "user_pool_name" {
  type        = string
  description = "Cognito user pool name"
  default     = "bmb_users_pool"
}