variable "prefix" {
  description = "Prefix for resources created."
}

variable "domain_suffix" {
  default = "example.net"
}

variable "subnet_ids" {
  description = "The ID of the subnets to associate with the Client VPN endpoint."
  type = list(string)
}

variable "client_cidr_block" {
  description = "The vpn client IPv4 address cidr range between /12 and /22 from which to assign client IP addresses."
  default = "18.0.0.0/22"
}

# false: all trafic goes via the vpn
# true: only vpn traffic goes to the vpn
variable "split_tunnel" {
  type = bool
  default = false
}

# set this to the vpc default resolver, which is x.x.x.2
variable "dns_servers" {
  type = list(string)
  default = []
}

# expected values - certificate-authentication to use certificate-based authentication, directory-service-authentication to use Active Directory authentication, or federated-authentication
variable "client_auth" {
  description = "The expected type of the VPN authentication"
  default = "certificate-authentication"
}

variable "saml_provider_arn" {
  description = "The arn of the pre configured SAML app"
  type = string
  default = ""
}

variable "vpc_id" {
  description = "The VPC id containing security groups, must be included if passing security group ids"
  type = string
}

variable "security_group_ids" {
  description = "The security group ids required, must pass vpc ID as well"
  type = list(string)
  default = []
}

variable "cloudwatch_enabled" {
  description = "Enables logging"
  type = bool
  default = true
}

variable "cloudwatch_log_group" {
  description = "The name of the cloudwatch log group."
  type        = string
  default = "vpn_endpoint_cloudwatch_log_group"
}

variable "cloudwatch_log_stream" {
  description = "The name of the cloudwatch log stream."
  type        = string
  default = "vpn_endpoint_cloudwatch_log_stream"
}
