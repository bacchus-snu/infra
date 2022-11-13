module "eks_bacchus_dev" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 18.20"

  cluster_name                    = "bacchus-dev"
  cluster_version                 = "1.22"
  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true

  cluster_addons = {
    vpc-cni = {
      addon_version     = "v1.11.0-eksbuild.1"
      resolve_conflicts = "OVERWRITE"
    }
    coredns = {
      addon_version     = "v1.8.7-eksbuild.1"
      resolve_conflicts = "OVERWRITE"
    }
    kube-proxy = {
      addon_version = "v1.22.6-eksbuild.1"
    }
  }

  vpc_id     = module.vpc_bacchus_dev.vpc_id
  subnet_ids = module.vpc_bacchus_dev.private_subnets

  cluster_enabled_log_types = []

  manage_aws_auth_configmap = false

  aws_auth_users = [for username in aws_iam_group_membership.bacchus_admin.users : {
    userarn  = aws_iam_user.bacchus[username].arn,
    username = username,
    groups   = ["system:masters"]
  }]
}
