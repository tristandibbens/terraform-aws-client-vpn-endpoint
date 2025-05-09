// Check ERs related to Client VPN Endpoint terraform resource and replace aws cli with the new resource attributes
// https://github.com/terraform-providers/terraform-provider-aws/issues/7494
// https://github.com/terraform-providers/terraform-provider-aws/pull/7564
// https://github.com/terraform-providers/terraform-provider-aws/issues/7831
// https://github.com/terraform-providers/terraform-provider-aws/issues/7523

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
    }
  }
}

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

resource "aws_ec2_client_vpn_authorization_rule" "allow_all" {
  count = var.update_certificate_toggle ? 0 : 1 # expectation is that we can pass a variable from the calling module and not edit the code pass true to destroy and re run with false
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.client-vpn-endpoint.id
  target_network_cidr    = "0.0.0.0/0"
  authorize_all_groups   = true
  description            = "Allow all clients access to all networks"
  
  depends_on = [
    aws_ec2_client_vpn_network_association.client-vpn-network-association
  ]
}


resource "null_resource" "export-client-config" {
  count = var.update_certificate_toggle ? 0 : 1 # expectation is that we can pass a variable from the calling module and not edit the code pass true to destroy and re run with false
  provisioner "local-exec" {
    when = create
    command = "aws ec2 export-client-vpn-client-configuration --client-vpn-endpoint-id ${aws_ec2_client_vpn_endpoint.client-vpn-endpoint.id} --output text > ./client-config.ovpn"
  }

  depends_on = [
    aws_ec2_client_vpn_endpoint.client-vpn-endpoint,
    aws_ec2_client_vpn_authorization_rule.allow_all,
    aws_ec2_client_vpn_network_association.client-vpn-network-association,
  ]
}

resource "null_resource" "append-client-config-certs" {
  count = var.update_certificate_toggle ? 0 : 1 # expectation is that we can pass a variable from the calling module and not edit the code pass true to destroy and re run with false
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
