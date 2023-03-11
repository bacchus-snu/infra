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
  zone_id = cloudflare_zone.bacchus.id

  name  = tolist(aws_acm_certificate.bacchus_io.domain_validation_options)[0].name
  type  = tolist(aws_acm_certificate.bacchus_io.domain_validation_options)[0].type
  value = tolist(aws_acm_certificate.bacchus_io.domain_validation_options)[0].record

  proxied = false
}

resource "aws_acm_certificate_validation" "bacchus_io" {
  certificate_arn         = aws_acm_certificate.bacchus_io.arn
  validation_record_fqdns = [cloudflare_record.bacchus_io_validation.hostname]
}
