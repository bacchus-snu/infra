resource "random_id" "webhook_secret" {
  byte_length = 32
}

resource "cloudflare_zero_trust_tunnel_cloudflared" "webhook" {
  account_id = "9d0fe600126436ae84ee3f9ed2f60a9c"
  name       = "argocd-webhook"
  secret     = random_id.webhook_secret.b64_std
}

resource "cloudflare_zero_trust_tunnel_cloudflared_config" "webhook" {
  account_id = cloudflare_zero_trust_tunnel_cloudflared.webhook.account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.webhook.id

  config {
    ingress_rule {
      hostname = "argocd-webhook.bacchus.io"
      path     = "api/webhook"
      service  = "https://argocd.internal.bacchus.io"
      origin_request {
        http_host_header = "argocd.internal.bacchus.io"
      }
    }
    # catch-all
    ingress_rule {
      service = "http_status:404"
    }
  }
}
