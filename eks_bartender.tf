# https://github.com/terraform-aws-modules/terraform-aws-eks/issues/2009#issuecomment-1096628912
provider "kubernetes" {
  alias = "bartender"

  host                   = module.eks_bartender.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks_bartender.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    # This requires the awscli to be installed locally where Terraform is executed
    args = ["eks", "get-token", "--cluster-name", module.eks_bartender.cluster_id]
  }
}

provider "helm" {
  alias = "bartender"

  kubernetes {
    host                   = module.eks_bartender.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks_bartender.cluster_certificate_authority_data)

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      # This requires the awscli to be installed locally where Terraform is executed
      args = ["eks", "get-token", "--cluster-name", module.eks_bartender.cluster_id]
    }
  }
}

module "ebs_csi_irsa_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.4"

  role_name             = "ebs-csi"
  attach_ebs_csi_policy = true

  oidc_providers = {
    main = {
      provider_arn               = module.eks_bartender.oidc_provider_arn
      namespace_service_accounts = ["kube-system:ebs-csi-controller-sa"]
    }
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

module "cluster_autoscaler_irsa_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.4"

  role_name                        = "cluster-autoscaler"
  attach_cluster_autoscaler_policy = true
  cluster_autoscaler_cluster_ids   = [module.eks_bartender.cluster_id]

  oidc_providers = {
    main = {
      provider_arn               = module.eks_bartender.oidc_provider_arn
      namespace_service_accounts = ["kube-system:cluster-autoscaler"]
    }
  }
}

module "vpc_cni_irsa_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.4"

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
  version = "~> 5.4"

  role_name                              = "aws-load-balance-controller"
  attach_load_balancer_controller_policy = true

  oidc_providers = {
    main = {
      provider_arn               = module.eks_bartender.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-load-balancer-controller"]
    }
  }
}

module "eks_bartender" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 18.29"

  providers = {
    kubernetes = kubernetes.bartender
  }

  cluster_name                    = "bartender"
  cluster_version                 = "1.23"
  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true

  cluster_addons = {
    vpc-cni = {
      addon_version     = "v1.11.0-eksbuild.1"
      resolve_conflicts = "OVERWRITE"
    }
    coredns = {
      addon_version     = "v1.8.7-eksbuild.2"
      resolve_conflicts = "OVERWRITE"
    }
    kube-proxy = {
      addon_version = "v1.23.7-eksbuild.1"
    }
    aws-ebs-csi-driver = {
      addon_version            = "v1.10.0-eksbuild.1"
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
  node_security_group_additional_rules = {
    ingress_self_all = {
      description = "Node to node all ports/protocols"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "ingress"
      self        = true
    }
    egress_all = {
      description      = "Node all egress"
      protocol         = "-1"
      from_port        = 0
      to_port          = 0
      type             = "egress"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    }
    ingress_allow_access_from_control_plane = {
      description = "Allow access from control plane to webhook port of AWS load balancer controller"

      type                          = "ingress"
      protocol                      = "tcp"
      from_port                     = 9443
      to_port                       = 9443
      source_cluster_security_group = true
    }
  }

  cluster_enabled_log_types = []

  eks_managed_node_group_defaults = {
    ami_type       = "AL2_x86_64"
    instance_types = ["t3.medium"]
    iam_role_additional_policies = [
      "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
    ]
  }

  eks_managed_node_groups = {
    workers = {
      name = "bartender-workers"

      disk_size = 50

      max_size     = 4
      desired_size = 2
    }
  }

  manage_aws_auth_configmap = true

  aws_auth_users = [for username in aws_iam_group_membership.bacchus_admin.users : {
    userarn  = aws_iam_user.bacchus[username].arn,
    username = username,
    groups   = ["system:masters"]
  }]
}

resource "helm_release" "aws_load_balancer_controller" {
  provider = helm.bartender

  name      = "aws-load-balancer-controller"
  namespace = "kube-system"

  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  version    = "1.4.4"

  set {
    name  = "clusterName"
    value = module.eks_bartender.cluster_id
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = module.aws_lbc_irsa_role.iam_role_arn
  }
}

resource "helm_release" "cluster_autoscaler" {
  name      = "cluster-autoscaler"
  namespace = "kube-system"

  repository = "https://kubernetes.github.io/autoscaler"
  chart      = "cluster-autoscaler"
  version    = "9.21.0"

  set {
    name  = "awsRegion"
    value = "ap-northeast-2"
  }

  set {
    name  = "autoDiscovery.clusterName"
    value = module.eks_bartender.cluster_id
  }

  set {
    name  = "rbac.serviceAccount.name"
    value = "cluster-autoscaler"
  }

  set {
    name  = "rbac.serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = module.cluster_autoscaler_irsa_role.iam_role_arn
  }
}

resource "helm_release" "metrics_server" {
  provider = helm.bartender

  name      = "metrics-server"
  namespace = "kube-system"

  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  chart      = "metrics-server"
  version    = "3.8.2"

  set {
    name  = "containerPort"
    value = "10250"
  }
}

resource "helm_release" "cert_manager" {
  provider = helm.bartender

  name      = "cert-manager"
  namespace = "cert-manager"

  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  version    = "1.9.1"

  create_namespace = true

  set {
    name  = "installCRDs"
    value = "true"
  }
}

variable "cloudflare_api_token" {
  type = string
}

resource "kubernetes_namespace" "external_dns" {
  provider = kubernetes.bartender

  metadata {
    name = "external-dns"
  }
}

resource "kubernetes_secret" "external_dns" {
  provider = kubernetes.bartender

  metadata {
    name      = "cloudflare"
    namespace = kubernetes_namespace.external_dns.id
  }

  data = {
    CF_API_TOKEN = var.cloudflare_api_token
  }
}

resource "helm_release" "external_dns" {
  provider = helm.bartender

  name      = "external-dns"
  namespace = "external-dns"

  repository = "https://kubernetes-sigs.github.io/external-dns"
  chart      = "external-dns"
  version    = "1.11.0"

  depends_on = [
    kubernetes_secret.external_dns
  ]

  values = [
    file("helm/externaldns.yaml")
  ]
}

variable "github_oauth_client_secret" {
  type = string
}

resource "kubernetes_namespace" "dashboard" {
  provider = kubernetes.bartender

  metadata {
    name = "dashboard"
  }
}

resource "kubernetes_secret" "github_oauth" {
  provider = kubernetes.bartender

  metadata {
    name      = "github-oauth"
    namespace = kubernetes_namespace.dashboard.id
  }

  data = {
    secret = var.github_oauth_client_secret
  }
}

resource "helm_release" "dashboard" {
  provider = helm.bartender

  name      = "dashboard"
  namespace = kubernetes_namespace.dashboard.id

  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = "40.2.0"

  depends_on = [
    kubernetes_secret.github_oauth
  ]

  values = [
    file("helm/kube-prometheus-stack.yaml")
  ]
}
