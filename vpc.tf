module "vpc_bartender" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.13.0"

  name = "bartender"
  cidr = "10.1.0.0/16"

  azs             = ["ap-northeast-2a", "ap-northeast-2b", "ap-northeast-2c", "ap-northeast-2d"]
  private_subnets = ["10.1.0.0/19", "10.1.32.0/19", "10.1.64.0/19", "10.1.96.0/19"]
  public_subnets  = ["10.1.128.0/19", "10.1.160.0/19", "10.1.192.0/19", "10.1.224.0/19"]

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = "1",
  }
  public_subnet_tags = {
    "kubernetes.io/role/elb" = "1",
  }
}

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

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = "1",
  }
  public_subnet_tags = {
    "kubernetes.io/role/elb" = "1",
  }
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

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = "1",
  }
  public_subnet_tags = {
    "kubernetes.io/role/elb" = "1",
  }
}

resource "aws_default_vpc" "bacchus" {
  tags = {
    Name = "default"
  }
}

resource "aws_security_group" "wireguard_with_ssh" {
  name        = "wireguard_with_ssh"
  description = "Allow SSH and WireGuard traffic"
  vpc_id      = aws_default_vpc.bacchus.id
}

resource "aws_security_group_rule" "wireguard_with_ssh_egress" {
  security_group_id = aws_security_group.wireguard_with_ssh.id

  type      = "egress"
  protocol  = "all"
  from_port = 0
  to_port   = 0

  cidr_blocks      = ["0.0.0.0/0"]
  ipv6_cidr_blocks = ["::/0"]
}

resource "aws_security_group_rule" "wireguard_with_ssh_ingress" {
  for_each = { for spec in [["tcp", 22], ["udp", 51820]] : "${spec[0]}-${spec[1]}" => spec }

  security_group_id = aws_security_group.wireguard_with_ssh.id

  type      = "ingress"
  protocol  = each.value[0]
  from_port = each.value[1]
  to_port   = each.value[1]

  cidr_blocks      = ["0.0.0.0/0"]
  ipv6_cidr_blocks = ["::/0"]
}
