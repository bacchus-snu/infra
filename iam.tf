locals {
  users = {
    "tirr" = {
      pgp_key         = "keybase:vbchunguk",
      is_admin        = true,
      console_enabled = true,
    },
    "ryul99" = {
      pgp_key         = "keybase:ryul_99",
      is_admin        = true,
      console_enabled = true,
    },
    "skystar" = {
      pgp_key         = "keybase:skystar",
      is_admin        = true,
      console_enabled = true,
    },
    "cseteram" = {
      pgp_key         = "keybase:cseteram",
      is_admin        = true,
      console_enabled = true,
    },
    "jhuni" = {
      pgp_key         = "keybase:jhuni",
      is_admin        = true,
      console_enabled = true,
    },
    "whnbaek" = {
      pgp_key         = file("./keys/whnbaek.gpg"),
      is_admin        = true,
      console_enabled = true,
    },
    "nevivurn" = {
      pgp_key         = file("./keys/nevivurn.gpg"),
      is_admin        = true,
      console_enabled = true,
    },
    "minty99" = {
      pgp_key         = "keybase:minty99",
      is_admin        = true,
      console_enabled = true,
    },
    "terraform-cloud" = {
      pgp_key         = "",
      is_admin        = true,
      console_enabled = false,
    },
  }
}

data "aws_iam_policy" "administrator_access" {
  name = "AdministratorAccess"
}

resource "aws_iam_user" "bacchus" {
  for_each = local.users

  name = each.key
  path = "/"
}

resource "aws_iam_user_login_profile" "bacchus" {
  for_each = {
    for user in aws_iam_user.bacchus :
    user.name => local.users[user.name]["pgp_key"]
    if local.users[user.name]["console_enabled"]
  }

  user    = each.key
  pgp_key = each.value == "" ? null : each.value

  password_reset_required = true

  lifecycle {
    ignore_changes = [
      pgp_key,
      password_length,
      password_reset_required,
    ]
  }
}

resource "aws_iam_access_key" "bacchus" {
  for_each = {
    for user in aws_iam_user.bacchus :
    user.name => local.users[user.name]["pgp_key"]
  }

  user    = each.key
  pgp_key = each.value == "" ? null : each.value

  lifecycle {
    ignore_changes = [
      pgp_key,
    ]
  }
}

resource "aws_iam_group" "bacchus_admin" {
  name = "bacchus-admin"
  path = "/"
}

resource "aws_iam_group_policy_attachment" "bacchus_admin" {
  group      = aws_iam_group.bacchus_admin.name
  policy_arn = data.aws_iam_policy.administrator_access.arn
}

resource "aws_iam_group_membership" "bacchus_admin" {
  name = "bacchus_admin_membership"

  group = aws_iam_group.bacchus_admin.name
  users = [for user in aws_iam_user.bacchus : user.name if local.users[user.name]["is_admin"]]
}

resource "aws_iam_policy" "aws_eks_lbc_policy" {
  name = "AWSLoadBalancerControllerIAMPolicy"
  path = "/"

  policy = file("./aws_eks_lbc_policy.json")
}
