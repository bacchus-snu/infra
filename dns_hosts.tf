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

    # 2024-fall classes
    ds01 = "147.46.91.26"
    ds02 = "147.46.91.28"
    ds03 = "147.46.91.34"
    ds04 = "147.46.91.37"
    ds05 = "147.46.91.38"
    ds06 = "147.46.91.39"
    ds07 = "147.46.91.40"
    ds08 = "147.46.91.41"
    ds09 = "147.46.91.42"
    ds10 = "147.46.91.43"
    ds11 = "147.46.91.45"
    ds12 = "147.46.91.52"
    ds13 = "147.46.91.65"
    ds14 = "147.46.91.69"
    
    sp01 = "147.46.91.16"
    sp02 = "147.46.91.18"
    sp03 = "147.46.91.251"
    sp04 = "147.46.91.25"
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
