resource "aws_acm_certificate" "bacchus_io" {
  lifecycle {
    create_before_destroy = true
  }

  domain_name               = "bacchus.io"
  subject_alternative_names = ["*.bacchus.io"]
  validation_method         = "DNS"

  key_algorithm = "EC_secp384r1"
}

resource "cloudflare_record" "bacchus_io_validation" {
  for_each = {
    for dvo in aws_acm_certificate.bacchus_io.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  zone_id = cloudflare_zone.bacchus.id

  name  = each.value.name
  type  = each.value.type
  value = each.value.record

  proxied = false
}

resource "aws_acm_certificate_validation" "bacchus_io" {
  certificate_arn = aws_acm_certificate.bacchus_io.arn
  validation_record_fqdns = [
    for dvo in aws_acm_certificate.bacchus_io.domain_validation_options :
    cloudflare_record.bacchus_io_validation[dvo.domain_name].hostname
  ]
}
