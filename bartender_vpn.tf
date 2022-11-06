data "aws_ami" "amazon_linux_2" {
  most_recent = true

  owners = ["amazon"]

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "name"
    values = ["amzn2-ami-*"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "bacchus_vpn_bartender_kr" {
  ami           = data.aws_ami.amazon_linux_2.id
  instance_type = "t3a.micro"

  vpc_security_group_ids = [
    aws_security_group.bacchus_vpn_bartender_kr.id,
  ]
  subnet_id         = module.vpc_bartender.public_subnets[0]
  source_dest_check = false

  root_block_device {
    volume_size = 20
  }

  lifecycle {
    ignore_changes = [ami]
  }

  iam_instance_profile = aws_iam_instance_profile.ec2_ssm.name

  tags = {
    Name = "bacchus-vpn-bartender-kr"
  }
}

resource "aws_eip" "bacchus_vpn_bartender_kr" {
  instance = aws_instance.bacchus_vpn_bartender_kr.id
}

resource "aws_security_group" "bacchus_vpn_bartender_kr" {
  name   = "bartender-wireguard-gateway"
  vpc_id = module.vpc_bartender.vpc_id

  ingress {
    description = "wireguard encrypted traffic"
    from_port   = 51820
    to_port     = 51821
    protocol    = "udp"
    cidr_blocks = ["147.46.0.0/15"]
  }
  ingress {
    description     = "traffic forwarding to SNU"
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = [] # TODO
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}
