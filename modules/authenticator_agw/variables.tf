variable "api_name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "vpc_link_subnets" {
  type = list(string)
}

variable "nlb_listener_arn" {
  type = string
}

variable "profile" {
  type = string
}

variable "region" {
  type = string
}
