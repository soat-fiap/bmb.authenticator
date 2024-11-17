variable "api_name" {
  description = "API Name"
  type        = string
  default     = "authenticator"
}

variable "vpc_name" {
  description = "VPC Name"
  type        = string
  default     = "postech-fiap-vpc"
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
  default     = "bmb-users-pool-dev"
}

variable "jwt_secret" {
  type      = string
  sensitive = true
  default   = "PkOhRwy6UtniEMo7lLWp3bADctYgnDHCTvH+2YkDeGg="
}

variable "jwt_audience" {
  type    = string
  default = "https://localhost:7000"
}

variable "jwt_issuer" {
  type    = string
  default = "https://localhost:7000"
}

variable "services" {
   type = map(object({
    namespace = string
    auth      = bool
  }))
  default = {
    "payment" = {
      namespace = "fiap-payment"
      auth      = true
    }
    "production" = {
      namespace = "fiap-production"
      auth      = true
    }
    "orders" = {
      namespace = "fiap-orders"
      auth      = true
    }
    # "log" = {
    #   namespace = "fiap-log"
    #   auth = false
    # }
  }
}
