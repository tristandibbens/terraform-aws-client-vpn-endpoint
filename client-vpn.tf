// Check ERs related to Client VPN Endpoint terraform resource and replace aws cli with the new resource attributes
// https://github.com/terraform-providers/terraform-provider-aws/issues/7494
// https://github.com/terraform-providers/terraform-provider-aws/pull/7564
// https://github.com/terraform-providers/terraform-provider-aws/issues/7831
// https://github.com/terraform-providers/terraform-provider-aws/issues/7523

resource "aws_acm_certificate" "client_cert" {
  private_key       = file("${path.root}/certs/client.${local.domain}.key")
  certificate_body  = file("${path.root}/certs/client.${local.domain}.crt")
  certificate_chain = file("${path.root}/certs/ca.crt")

  # Don't replace cert if you re-run the script to generate certs. For ci/cd use.
  #lifecycle {
  #  ignore_changes = all
  #}

  tags = {
    Name = "client.${local.domain}"
  }
}

resource "aws_acm_certificate" "server_cert" {
  private_key       = file("${path.root}/certs/server.${local.domain}.key")
  certificate_body  = file("${path.root}/certs/server.${local.domain}.crt")
  certificate_chain = file("${path.root}/certs/ca.crt")

  # Don't replace cert if you re-run the script to generate certs. For ci/cd use.
  #lifecycle {
  #  ignore_changes = all
  #}

  tags = {
    Name = "server.${local.domain}"
  }
}

resource "aws_ec2_client_vpn_endpoint" "client-vpn-endpoint" {
  description            = "${var.prefix} terraform-clientvpn-endpoint"
  server_certificate_arn = aws_acm_certificate.server_cert.arn
  client_cidr_block      = var.client_cidr_block
  split_tunnel = var.split_tunnel
  dns_servers = var.dns_servers
  vpc_id      = var.vpc_id
  security_group_ids = var.security_group_ids

  authentication_options {
    type                        = var.client_auth
    root_certificate_chain_arn  = aws_acm_certificate.client_cert.arn
    saml_provider_arn           = var.saml_provider_arn
  }

  connection_log_options {
    enabled               = var.cloudwatch_enabled
    cloudwatch_log_group  = aws_cloudwatch_log_group.client_vpn.name
    cloudwatch_log_stream = aws_cloudwatch_log_stream.client_vpn.name
  }

  tags = {
    Name = var.prefix
  }
}

resource "aws_ec2_client_vpn_network_association" "client-vpn-network-association" {
  count = length(var.subnet_ids)
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.client-vpn-endpoint.id
  subnet_id              = var.subnet_ids[count.index]
}

resource "null_resource" "authorize-client-vpn-ingress" {
  provisioner "local-exec" {
    when = create
    command = "aws ec2 authorize-client-vpn-ingress --client-vpn-endpoint-id ${aws_ec2_client_vpn_endpoint.client-vpn-endpoint.id} --target-network-cidr 0.0.0.0/0 --authorize-all-groups"
  }

  depends_on = [
    aws_ec2_client_vpn_endpoint.client-vpn-endpoint,
    aws_ec2_client_vpn_network_association.client-vpn-network-association
  ]
}

resource "null_resource" "export-client-config" {
  provisioner "local-exec" {
    when = create
    command = "aws ec2 export-client-vpn-client-configuration --client-vpn-endpoint-id ${aws_ec2_client_vpn_endpoint.client-vpn-endpoint.id} --output text > ./client-config.ovpn"
  }

  depends_on = [
    aws_ec2_client_vpn_endpoint.client-vpn-endpoint,
    null_resource.authorize-client-vpn-ingress,
    null_resource.create-client-vpn-route,
    aws_ec2_client_vpn_network_association.client-vpn-network-association,
  ]
}

resource "null_resource" "append-client-config-certs" {
  provisioner "local-exec" {
    when = create
    command = "${path.module}/scripts/add_certs_to_client_config.sh ${local.domain} ${local.dns_servers}"
  }

  depends_on = [null_resource.export-client-config]
}

resource "aws_cloudwatch_log_group" "client_vpn" {
  name = var.cloudwatch_log_group
}

resource "aws_cloudwatch_log_stream" "client_vpn" {
  name           = var.cloudwatch_log_stream
  log_group_name = aws_cloudwatch_log_group.client_vpn.name
}

/*
*/
