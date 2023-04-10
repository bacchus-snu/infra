module "vpc_practice" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "4.0.1"

  name = "practice"
  cidr = "10.1.0.0/16"

  azs            = ["ap-northeast-2a"]
  public_subnets = ["10.1.128.0/19"]

  enable_dns_hostnames = true
}

resource "aws_instance" "bacchus_practice" {
  ami           = data.aws_ami.debian_bullseye.id
  instance_type = "t3.micro"

  vpc_security_group_ids = [
    aws_security_group.bacchus_practice.id,
  ]
  subnet_id = module.vpc_practice.public_subnets[0]

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
    Name = "bacchus-practice"
  }
}

resource "aws_eip" "bacchus_practice" {
  instance = aws_instance.bacchus_practice.id
}

resource "aws_security_group" "bacchus_practice" {
  name   = "bacchus_practice"
  vpc_id = module.vpc_practice.vpc_id

  ingress {
    description = "Allow SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "cloudflare_record" "bacchus_practice" {
  zone_id = cloudflare_zone.bacchus.id

  name  = "practice"
  value = aws_eip.bacchus_practice.public_ip
  type  = "A"
}
