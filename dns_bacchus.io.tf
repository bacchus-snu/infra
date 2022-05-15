resource "cloudflare_zone" "bacchus" {
  zone = "bacchus.io"
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
