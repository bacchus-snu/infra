resource "random_id" "webhook_secret" {
  byte_length = 32
}

resource "cloudflare_tunnel" "webhook" {
  account_id = "9d0fe600126436ae84ee3f9ed2f60a9c"
  name = "argocd-webhook"
  secret = random_id.webhook_secret.b64_std
  config_src = "cloudflare"
}

resource "cloudflare_tunnel_config" "webhook" {
  account_id = cloudflare_tunnel.webhook.account_id
  tunnel_id = cloudflare_tunnel.webhook.id

  config {
    ingress_rule {
      hostname = "argocd-webhook.bacchus.io"
      path = "/api/webhook"
      service = "https://argocd.bacchus.io"
      origin_request {
        http_host_header = "argocd.bacchus.io"
      }
    }
  }
}
