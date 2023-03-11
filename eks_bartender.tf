provider "kubernetes" {
  alias = "bartender"

  host                   = module.eks_bartender.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks_bartender.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", module.eks_bartender.cluster_name]
  }
}

resource "kubernetes_storage_class" "gp2" {
  provider = kubernetes.bartender

  metadata {
    name = "gp2"
    annotations = {
      "storageclass.kubernetes.io/is-default-class" = "false"
    }
  }

  storage_provisioner = "kubernetes.io/aws-ebs"
  volume_binding_mode = "WaitForFirstConsumer"
  reclaim_policy      = "Delete"

  parameters = {
    fsType = "ext4"
    type   = "gp2"
  }
}

resource "kubernetes_storage_class" "gp3" {
  provider = kubernetes.bartender

  metadata {
    name = "gp3"
    annotations = {
      "storageclass.kubernetes.io/is-default-class" = "true"
    }
  }

  storage_provisioner = "ebs.csi.aws.com"
  volume_binding_mode = "WaitForFirstConsumer"

  parameters = {
    type = "gp3"
  }
}

module "ebs_csi_irsa_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.13"

  role_name             = "ebs-csi"
  attach_ebs_csi_policy = true

  oidc_providers = {
    main = {
      provider_arn               = module.eks_bartender.oidc_provider_arn
      namespace_service_accounts = ["kube-system:ebs-csi-controller-sa"]
    }
  }
}


module "cluster_autoscaler_irsa_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.13"

  role_name                        = "cluster-autoscaler"
  attach_cluster_autoscaler_policy = true
  cluster_autoscaler_cluster_ids   = [module.eks_bartender.cluster_name]

  oidc_providers = {
    main = {
      provider_arn               = module.eks_bartender.oidc_provider_arn
      namespace_service_accounts = ["kube-system:cluster-autoscaler"]
    }
  }
}

module "vpc_cni_irsa_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.13"

  role_name             = "vpc-cni"
  attach_vpc_cni_policy = true
  vpc_cni_enable_ipv4   = true

  oidc_providers = {
    main = {
      provider_arn               = module.eks_bartender.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-node"]
    }
  }
}

module "aws_lbc_irsa_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.13"

  role_name                              = "aws-load-balance-controller"
  attach_load_balancer_controller_policy = true

  oidc_providers = {
    main = {
      provider_arn               = module.eks_bartender.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-load-balancer-controller"]
    }
  }
}

module "external_secrets_irsa_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.13"

  role_name                      = "external-secrets"
  attach_external_secrets_policy = true

  oidc_providers = {
    main = {
      provider_arn               = module.eks_bartender.oidc_provider_arn
      namespace_service_accounts = ["external-secrets:external-secrets"]
    }
  }
}

module "eks_bartender" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.10"

  providers = {
    kubernetes = kubernetes.bartender
  }

  cluster_name                    = "bartender"
  cluster_version                 = "1.24"
  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true

  cluster_addons = {
    vpc-cni = {
      preserve    = true
      most_recent = true

      service_account_role_arn = module.vpc_cni_irsa_role.iam_role_arn
    }
    coredns = {
      preserve    = true
      most_recent = true
    }
    kube-proxy = {
      preserve    = true
      most_recent = true
    }
    aws-ebs-csi-driver = {
      preserve    = true
      most_recent = true

      service_account_role_arn = module.ebs_csi_irsa_role.iam_role_arn
    }
  }

  vpc_id     = module.vpc_bartender.vpc_id
  subnet_ids = module.vpc_bartender.private_subnets

  # https://github.com/terraform-aws-modules/terraform-aws-eks/issues/2042#issuecomment-1109902831
  # Extend cluster security group rules
  cluster_security_group_additional_rules = {
    egress_nodes_ephemeral_ports_tcp = {
      description                = "To node 1025-65535"
      protocol                   = "tcp"
      from_port                  = 1025
      to_port                    = 65535
      type                       = "egress"
      source_node_security_group = true
    }
  }

  # Extend node-to-node security group rules
  node_security_group_additional_rules = {}

  cluster_enabled_log_types = []

  eks_managed_node_group_defaults = {
    ami_type       = "AL2_x86_64"
    instance_types = ["t3.large"]

    iam_role_additional_policies = {
      additional = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
    }
  }

  eks_managed_node_groups = {
    workers_b = {
      name = "bartender-workers-b"

      disk_size = 50

      max_size     = 2
      desired_size = 1

      subnet_ids = [module.vpc_bartender.private_subnets[1]]
    }
    workers_d = {
      name = "bartender-workers-d"

      disk_size = 50

      max_size     = 2
      desired_size = 1

      subnet_ids = [module.vpc_bartender.private_subnets[3]]
    }
  }

  manage_aws_auth_configmap = true

  aws_auth_users = [for username in aws_iam_group_membership.bacchus_admin.users : {
    userarn  = aws_iam_user.bacchus[username].arn,
    username = username,
    groups   = ["system:masters"]
  }]
}
