locals {
  dns_snucse-org = [
    # github site verification
    {
      name  = "_github-pages-challenge-bacchus-snu"
      type  = "TXT"
      value = "7b9f5a46f00083087748e0dec86020"
    },

    # SNUCSE
    {
      name  = "snucse.org"
      type  = "CNAME"
      value = "www.snucse.org"
    },
    {
      name  = "*"
      type  = "CNAME"
      value = "mimosa.snucse.org"
    },

    # gh pages
    {
      name  = "bacchus"
      type  = "CNAME"
      value = "bacchus-snu.github.io"
    },
    {
      name  = "gpu"
      type  = "CNAME"
      value = "bacchus-snu.github.io"
    },

    # package mirror and repo
    {
      name  = "repo"
      type  = "CNAME"
      value = "blanc.snucse.org"
    },
    {
      name  = "mirror"
      type  = "CNAME"
      value = "blanc.snucse.org"
    },

    # GPU image registries
    {
      name  = "registry.bentley"
      type  = "CNAME"
      value = "bentley.snucse.org"
    },
    {
      name  = "registry.ferrari"
      type  = "CNAME"
      value = "ferrari.snucse.org"
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

  name  = each.value.name
  type  = each.value.type
  value = each.value.value
}
