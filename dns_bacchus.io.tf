resource "cloudflare_zone" "bacchus" {
  account_id = "9d0fe600126436ae84ee3f9ed2f60a9c"
  zone       = "bacchus.io"
}

resource "cloudflare_zone" "snucse" {
  account_id = "9d0fe600126436ae84ee3f9ed2f60a9c"
  zone       = "snucse.org"
}

resource "cloudflare_record" "bacchus_horoyoi" {
  zone_id = cloudflare_zone.bacchus.id

  name  = "horoyoi"
  value = "147.46.113.163"
  type  = "A"
}

resource "cloudflare_record" "bacchus_vpn_kr" {
  zone_id = cloudflare_zone.bacchus.id

  name  = "kr.vpn"
  value = aws_eip.bacchus_vpn_kr.public_ip
  type  = "A"
}

resource "cloudflare_record" "bacchus_ghtxt" {
  zone_id = cloudflare_zone.bacchus.id
  name    = "_github-pages-challenge-bacchus-snu"
  value   = "24840067c4e087c4402adc898013cd"
  type    = "TXT"
}

resource "cloudflare_record" "snucse_ghtxt" {
  zone_id = cloudflare_zone.snucse.id
  name    = "_github-pages-challenge-bacchus-snu"
  value   = "7b9f5a46f00083087748e0dec86020"
  type    = "TXT"
}
