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

  vpc_id     = module.default_vpc.default_vpc_id
  subnet_ids = [for subnet in aws_default_subnet.default : subnet.id]

  cluster_enabled_log_types = []

  eks_managed_node_group_defaults = {
    ami_type       = "AL2_x86_64"
    instance_types = ["t3a.medium"]
    iam_role_additional_policies = [
      "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
    ]
  }

  eks_managed_node_groups = {
    workers = {
      name = "bacchus-dev-workers"

      create_launch_template = false
      launch_template_name   = ""

      disk_size = 50

      max_size     = 2
      desired_size = 2
    }
  }

  manage_aws_auth_configmap = true

  # TODO: do this for each admin user
  aws_auth_users = [
    {
      userarn  = "arn:aws:iam::642254835236:user/tirr",
      username = "tirr",
      groups   = ["system:masters"]
    }
  ]
}
