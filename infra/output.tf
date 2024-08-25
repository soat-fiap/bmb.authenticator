################################################################################
# API
################################################################################
output "api_endpoint" {
  description = "API address"
  value       = module.authenticator_api.endpoint
}

output "api" {
  description = "API address"
  value       = module.authenticator_api
}

################################################################################
# VPC
################################################################################
# output "vpc" {
#   value = data.aws_vpc.vpc_sample.id
# }

# output "subnets" {
#   value = data.aws_subnets.private_subnets.ids
# }


################################################################################
# LB
################################################################################
output "internal_elb" {
  value = data.aws_lb_listener.nlb_listener.arn
}
