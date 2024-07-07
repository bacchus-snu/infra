locals {
  dns_bacchus-io = [
    # github site verification
    {
      name  = "_github-pages-challenge-bacchus-snu"
      type  = "TXT"
      value = "24840067c4e087c4402adc898013cd"
    },

    # alias
    {
      name  = "horoyoi"
      type  = "CNAME"
      value = "horoyoi.snucse.org"
    },
    {
      name  = "waiter"
      type  = "CNAME"
      value = "kerkoporta.snucse.org"
    },

    # waffle development server
    {
      name  = "cse-dev-waffle"
      type  = "A"
      value = "147.46.242.210"
    },
  ]
}

resource "cloudflare_zone" "bacchus" {
  account_id = "9d0fe600126436ae84ee3f9ed2f60a9c"
  zone       = "bacchus.io"
}

resource "cloudflare_record" "bacchus_records" {
  for_each = { for r in local.dns_bacchus-io : "${r.name}_${r.type}" => r }

  zone_id = cloudflare_zone.bacchus.id
  comment = "managed by Terraform"

  name  = each.value.name
  type  = each.value.type
  value = each.value.value
}
