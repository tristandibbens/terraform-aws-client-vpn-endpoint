locals {
  domain = "${var.prefix}.${var.domain_suffix}"
  dns_servers = join(" ",var.dns_servers)
}
