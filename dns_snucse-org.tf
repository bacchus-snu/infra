locals {
  dns_snucse-org = [
    # github site verification
    {
      name    = "_github-pages-challenge-bacchus-snu"
      type    = "TXT"
      content = "7b9f5a46f00083087748e0dec86020"
    },

    # gh pages
    {
      name    = "gpu"
      type    = "CNAME"
      content = "bacchus-snu.github.io"
    },
    {
      name    = "sgs-docs"
      type    = "CNAME"
      content = "bacchus-snu.github.io"
    },

    # GPU image registries
    {
      name    = "registry.ferrari"
      type    = "CNAME"
      content = "ferrari.snucse.org"
    },

    # sommelier cluster
    {
      name    = "sommelier"
      type    = "CNAME"
      content = "kerkoporta.snucse.org"
    },

    # apex CNAME, gets flattened by Cloudflare
    {
      name    = "@"
      type    = "CNAME"
      content = "web_gateway.bacchus.io"
    },
  ]
}

resource "cloudflare_zone" "snucse" {
  account_id = "9d0fe600126436ae84ee3f9ed2f60a9c"
  zone       = "snucse.org"
}

resource "cloudflare_record" "snucse_records" {
  for_each = { for r in local.dns_snucse-org : "${r.name}_${r.type}" => r }

  zone_id = cloudflare_zone.snucse.id
  comment = "managed by Terraform"

  name    = each.value.name
  type    = each.value.type
  content = each.value.content
}

# bacchus.snucse.org cannot be CNAME due to other RRTYPEs (e.g., MX) on the same name.
resource "cloudflare_record" "snucse_bacchus" {
  for_each = toset([
    # bacchus-snu.github.io.
    "185.199.108.153",
    "185.199.109.153",
    "185.199.110.153",
    "185.199.111.153",
  ])

  zone_id = cloudflare_zone.snucse.id
  comment = "managed by Terraform"

  name    = "bacchus"
  type    = "A"
  content = each.value
}
