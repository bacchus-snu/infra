locals {
  dns_bacchus-io = [
    # github site verification
    {
      name    = "_github-pages-challenge-bacchus-snu"
      type    = "TXT"
      content = "\"24840067c4e087c4402adc898013cd\""
    },

    # alias
    {
      name    = "horoyoi"
      type    = "CNAME"
      content = "horoyoi.snucse.org"
    },
    {
      name    = "genesis"
      type    = "CNAME"
      content = "genesis.snucse.org"
    },
    {
      name    = "waiter"
      type    = "CNAME"
      content = "kerkoporta.snucse.org"
    },
    {
      name    = "web_gateway"
      type    = "CNAME"
      content = "kerkoporta.snucse.org"
    },
    # route argocd-webhook through tunnel
    {
      name    = "argocd-webhook"
      type    = "CNAME"
      content = cloudflare_zero_trust_tunnel_cloudflared.webhook.cname
      proxied = true
    },

    # waffle development server
    {
      name    = "cse-dev-waffle"
      type    = "A"
      content = "147.46.92.237"
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

  name    = each.value.name
  type    = each.value.type
  content = each.value.content

  proxied = lookup(each.value, "proxied", false)
}
