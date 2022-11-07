resource "aws_instance" "bacchus_vpn_bartender_kr" {
  ami           = data.aws_ami.debian_bullseye.id
  instance_type = "t3a.micro"

  vpc_security_group_ids = [
    aws_security_group.bacchus_vpn_bartender_kr.id,
  ]
  subnet_id         = module.vpc_bartender.public_subnets[0]
  source_dest_check = false

  root_block_device {
    volume_size = 30
  }

  user_data = <<-EOF
    #!/bin/bash
    mkdir /tmp/ssm
    cd /tmp/ssm
    wget https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/debian_amd64/amazon-ssm-agent.deb
    sudo dpkg -i amazon-ssm-agent.deb
    sudo systemctl enable --now amazon-ssm-agent
  EOF

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
    description = "traffic forwarding to SNU"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [module.vpc_bartender.vpc_cidr_block]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_route" "bacchus_vpn_bartender_kr" {
  for_each = toset(concat(
    module.vpc_bartender.public_route_table_ids,
    module.vpc_bartender.private_route_table_ids,
  ))

  route_table_id         = each.value
  destination_cidr_block = "147.46.0.0/15"
  network_interface_id   = aws_instance.bacchus_vpn_bartender_kr.primary_network_interface_id
}
