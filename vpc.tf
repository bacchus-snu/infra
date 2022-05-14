module "vpc_bacchus_prod" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.13.0"

  name = "bacchus-prod"
  cidr = "10.1.0.0/16"

  azs             = ["ap-northeast-2a", "ap-northeast-2b", "ap-northeast-2c", "ap-northeast-2d"]
  private_subnets = ["10.1.0.0/19", "10.1.32.0/19", "10.1.64.0/19", "10.1.96.0/19"]
  public_subnets  = ["10.1.128.0/19", "10.1.160.0/19", "10.1.192.0/19", "10.1.224.0/19"]

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true
}

module "vpc_bacchus_dev" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.13.0"

  name = "bacchus-dev"
  cidr = "10.0.0.0/16"

  azs             = ["ap-northeast-2a", "ap-northeast-2b", "ap-northeast-2c", "ap-northeast-2d"]
  private_subnets = ["10.0.0.0/19", "10.0.32.0/19", "10.0.64.0/19", "10.0.96.0/19"]
  public_subnets  = ["10.0.128.0/19", "10.0.160.0/19", "10.0.192.0/19", "10.0.224.0/19"]

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true
}
