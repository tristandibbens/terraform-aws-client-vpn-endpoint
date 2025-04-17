output "client_vpn_endpoint_id" {
  value = aws_ec2_client_vpn_endpoint.client-vpn-endpoint.id
}

output "client_vpn_cidrs" {
  value = aws_ec2_client_vpn_endpoint.client-vpn-endpoint.client_cidr_block
}
