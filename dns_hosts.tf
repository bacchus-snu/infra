locals {
  # canonical host-addres mappings
  dns_hosts = {
    # sgs dev environment (soju)
    cocktail = "147.46.240.85"

    # legacy GPU
    asahi   = "147.46.240.213"
    bernini = "147.46.240.245"
    cojito  = "147.46.240.221"
    derby   = "147.46.240.204"
    eggnog  = "147.46.240.145"
    faust   = "147.46.241.137"

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
    horoyoi = "147.46.127.36"
    genesis = "147.46.113.87"
    joker   = "147.46.242.183"
    martini = "147.46.240.44"
    mimosa  = "147.46.240.46"
    oloroso = "147.46.241.60"
    sherry  = "147.46.78.91"
    skyy    = "147.46.242.84"

    # misc virtual hosts
    kerkoporta = "147.46.92.174"

    # 2025-fall classes
    nw01 = "147.46.92.109"
    nw02 = "147.46.92.112"
    nw03 = "147.46.92.116"
    nw04 = "147.46.92.189"

    swpp01 = "147.46.240.83"
    dm01 = "147.46.240.79"

    # unused = "147.46.92.200"

    sp01 = "147.46.92.252"
    sp02 = "147.46.91.16"
    sp03 = "147.46.91.18"
    sp04 = "147.46.91.34"
    sp05 = "147.46.91.25"

    algo01 = "147.46.91.43"
    algo02 = "147.46.91.44"
    algo03 = "147.46.91.45"

    # unused = "147.46.91.26"
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
