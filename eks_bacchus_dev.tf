# https://github.com/terraform-aws-modules/terraform-aws-eks/issues/2009#issuecomment-1096628912
provider "kubernetes" {
  alias = "bacchus_dev"

  host                   = module.eks_bacchus_dev.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks_bacchus_dev.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1alpha1"
    command     = "aws"
    # This requires the awscli to be installed locally where Terraform is executed
    args = ["eks", "get-token", "--cluster-name", module.eks_bacchus_dev.cluster_id]
  }
}

module "eks_bacchus_dev" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 18.20"

  providers = {
    kubernetes = kubernetes.bacchus_dev
  }

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

  manage_aws_auth_configmap = true

  aws_auth_users = [for username in aws_iam_group_membership.bacchus_admin.users : {
    userarn  = aws_iam_user.bacchus[username].arn,
    username = username,
    groups   = ["system:masters"]
  }]
}
