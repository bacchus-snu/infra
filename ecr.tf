################################################################################
# Settings for IAM role to push container images to the AWS ECR
# For more information, see "https://docs.github.com/actions/deployment/security-hardening-your-deployments/about-security-hardening-with-openid-connect"
################################################################################

data "aws_iam_policy_document" "ecr_push_assume_role" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github_oidc_provider.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:bacchus-snu/*"]
    }
  }
}

data "aws_iam_policy_document" "ecr_push_inline_policy" {
  statement {
    effect = "Allow"
    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:BatchGetImage",
      "ecr:BatchCheckLayerAvailability",
      "ecr:CompleteLayerUpload",
      "ecr:GetDownloadUrlForLayer",
      "ecr:InitiateLayerUpload",
      "ecr:PutImage",
      "ecr:UploadLayerPart"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role" "ecr_push" {
  name        = "ecr-push-role"
  description = "Role for pushing container images to ECR"

  inline_policy {
    name   = "ecr-push-inline-policy"
    policy = data.aws_iam_policy_document.ecr_push_inline_policy.json
  }

  assume_role_policy = data.aws_iam_policy_document.ecr_push_assume_role.json
}

################################################################################
# List of registry
################################################################################

resource "aws_ecr_repository" "id_core" {
  name = "bacchus-id/core"
}

resource "aws_ecr_repository" "id_front" {
  name = "bacchus-id/front"
}
