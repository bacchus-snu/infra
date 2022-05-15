resource "cloudflare_zone" "bacchus" {
  zone = "bacchus.io"
}

resource "cloudflare_record" "bacchus_horoyoi" {
  zone_id = cloudflare_zone.bacchus.id

  name  = "horoyoi"
  value = "147.46.113.163"
  type  = "A"
}
