module "aws-client-vpn" {
  # How to run from github as a module:
  #source = "github.com/spicysomtam/terraform-aws-client-vpn-endpoint"
  # How eto run from the git checked out repo:
  source = "../"

  prefix = "k11"
  subnet_ids = ["subnet-36edb47e", "subnet-d12ba08b"]
  domain_suffix = "example.net"
}
