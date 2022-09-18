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

module "eks_bartender" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 18.20"

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
      addon_version = "v1.10.0-eksbuild.1"
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

      max_size     = 2
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

resource "aws_iam_role" "bartender_eks_lbc_assumerole" {
  name = "BartenderEKSLoadBalancerControllerRole"

  assume_role_policy = jsonencode({
    "Version" = "2012-10-17",
    "Statement" = [
      {
        "Effect" = "Allow",
        "Principal" = {
          "Federated" = module.eks_bartender.oidc_provider_arn,
        },
        "Action" = "sts:AssumeRoleWithWebIdentity",
        "Condition" = {
          "StringEquals" = {
            "${module.eks_bartender.oidc_provider}:aud" = "sts.amazonaws.com",
            "${module.eks_bartender.oidc_provider}:sub" = "system:serviceaccount:kube-system:aws-load-balancer-controller",
          },
        },
      },
    ],
  })
}

resource "aws_iam_role_policy_attachment" "bartender_eks_lbc" {
  role       = aws_iam_role.bartender_eks_lbc_assumerole.name
  policy_arn = aws_iam_policy.aws_eks_lbc_policy.arn
}

resource "helm_release" "aws_load_balancer_controller" {
  provider = helm.bartender

  name      = "aws-load-balancer-controller"
  namespace = "kube-system"

  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  version    = "1.4.4"

  set {
    name = "clusterName"
    value = module.eks_bartender.cluster_id
  }

  set {
    name = "serviceAccount.annotations.\"eks.amazonaws.com/role-arn\""
    value = aws_iam_role.bartender_eks_lbc_assumerole.arn
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

resource "helm_release" "external_dns" {
  provider = helm.bartender

  name      = "external-dns"
  namespace = "external-dns"

  repository = "https://kubernetes-sigs.github.io/external-dns"
  chart      = "external-dns"
  version    = "1.11.0"

  create_namespace = true

  values = [
    file("helm/externaldns.yaml")
  ]
}
