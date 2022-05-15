data "aws_ami" "debian_bullseye" {
  most_recent = true

  owners = ["amazon", "aws-marketplace"]

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "name"
    values = ["debian-11-*"]
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

resource "aws_instance" "bacchus_vpn" {
  ami           = data.aws_ami.debian_bullseye.id
  instance_type = "t3a.micro"

  vpc_security_group_ids = [
    aws_security_group.wireguard_with_ssh.id,
  ]

  user_data = file("${path.module}/setup-vpn.yml")

  root_block_device {
    volume_size = 20
  }
}

resource "aws_eip" "bacchus_vpn" {
  instance = aws_instance.bacchus_vpn.id
  vpc      = true
}
