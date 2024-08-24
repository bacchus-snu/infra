locals {
  # canonical host-addres mappings
  dns_hosts = {
    # legacy GPU
    asahi   = "147.46.240.213"
    bernini = "147.46.240.245"
    cojito  = "147.46.240.221"
    derby   = "147.46.240.204"
    eggnog  = "147.46.240.145"
    faust   = "147.46.240.144"

    # new GPU
    ferrari        = "147.46.15.75"
    "ipmi.ferrari" = "147.46.15.76"

    # legacy cluster
    glennfidich = "147.46.242.227"
    jackdaniels = "147.46.242.203"
    rum         = "147.46.242.138"

    # new cluster
    fizz  = "147.46.92.150"
    gin   = "147.46.92.166"
    ramos = "147.46.92.170"

    # misc physical hosts
    blanc   = "147.46.242.187"
    horoyoi = "147.46.113.120"
    joker   = "147.46.242.183"
    martini = "147.46.240.44"
    mimosa  = "147.46.240.46"
    oloroso = "147.46.241.60"
    sherry  = "147.46.78.91"
    skyy    = "147.46.242.84"

    # misc virtual hosts
    kerkoporta = "147.46.92.174"
  }
}

resource "cloudflare_record" "dns_hosts" {
  for_each = local.dns_hosts

  zone_id = cloudflare_zone.snucse.id
  comment = "managed by Terraform"

  name    = each.key
  type    = "A"
  content = each.value
}
