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
