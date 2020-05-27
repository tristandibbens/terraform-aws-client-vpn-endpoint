module "aws-client-vpn" {
  # How to run from github as a module:
  #source = "github.com/spicysomtam/terraform-aws-client-vpn-endpoint?ref=v1.0.1"
  # How eto run from the git checked out repo:
  source = "../"

  prefix = "k11"
  subnet_ids = ["subnet-105f1676"]
  domain_suffix = "example.net"
}
