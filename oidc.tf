data "tls_certificate" "dex_cert" {
  url = "https://auth.bacchus.io/dex"
}
resource "aws_iam_openid_connect_provider" "dex_provider" {
  client_id_list  = ["bacchus-aws"]
  thumbprint_list = [data.tls_certificate.dex_cert.certificates[0].sha1_fingerprint]
  url             = "https://auth.bacchus.io/dex"
}

data "aws_iam_policy_document" "dex_readonly_oidc" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.dex_provider.arn]
    }
    condition {
      test     = "ForAnyValue:StringEquals"
      variable = "auth.bacchus.io/dex:groups"
      values   = ["regular-members@bacchus.snucse.org"]
    }
  }
}
resource "aws_iam_role" "dex_readonly" {
  name        = "dex-readonly"
  description = "Role to be assumed with OIDC token"

  assume_role_policy  = data.aws_iam_policy_document.dex_readonly_oidc.json
  managed_policy_arns = ["arn:aws:iam::aws:policy/ReadOnlyAccess"]
}

resource "aws_iam_openid_connect_provider" "github_oidc_provider" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}
