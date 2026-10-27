moved {
  from = cloudflare_record.bacchus_records
  to   = cloudflare_dns_record.bacchus_records
}

moved {
  from = cloudflare_record.bacchus_atrium
  to   = cloudflare_dns_record.bacchus_atrium
}

moved {
  from = cloudflare_record.dns_hosts
  to   = cloudflare_dns_record.dns_hosts
}

moved {
  from = cloudflare_record.snucse_records
  to   = cloudflare_dns_record.snucse_records
}

moved {
  from = cloudflare_record.snucse_bacchus
  to   = cloudflare_dns_record.snucse_bacchus
}

moved {
  from = cloudflare_record.snucse_zest
  to   = cloudflare_dns_record.snucse_zest
}
