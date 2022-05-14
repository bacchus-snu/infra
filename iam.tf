locals {
  admin_users = [
    "tirr",
    "ryul99",
    "cseteram",
    "skystar",
    "terraform-cloud",
  ]
}

data "aws_iam_policy" "administrator_access" {
  name = "AdministratorAccess"
}

resource "aws_iam_user" "bacchus" {
  for_each = toset(local.admin_users)

  name = each.key
  path = "/"
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
  users = local.admin_users
}
