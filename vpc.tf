module "default_vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.13.0"

  create_vpc = false

  manage_default_vpc               = true
  default_vpc_name                 = "default"
  default_vpc_enable_dns_hostnames = true
}

resource "aws_default_subnet" "default" {
  for_each = toset(["ap-northeast-2a", "ap-northeast-2b", "ap-northeast-2c", "ap-northeast-2d"])

  availability_zone = each.key
}
