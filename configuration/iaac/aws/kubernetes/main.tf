# aws --version
# aws eks --region us-east-1 update-kubeconfig --name sumit-cluster
# Uses default VPC and Subnet. Create Your Own VPC and Private Subnets for Prod Usage.
# terraform-backend-state-in28minutes-123
# AKIA4AHVNOD7OOO6T4KI


terraform {
  backend "s3" {
    bucket = "mybucket" # Will be overridden from build
    key    = "path/to/my/key" # Will be overridden from build
    region = "ap-south-1"
  }
}

resource "aws_default_vpc" "default" {

}

data "aws_subnets" "default_subnets" {
  filter {
    name   = "vpc-id"
    values = [aws_default_vpc.default.id]
  }
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  cluster_name    = "sumit-cluster"
  cluster_version = "1.22"
  #subnet_ids         = ["subnet-072b3355fe2ae6bc4", "subnet-06dde89b4281a08ff"] #CHANGE
  subnet_ids = data.aws_subnets.default_subnets.ids
  vpc_id          = aws_default_vpc.default.id

  #vpc_id         = "vpc-1234556abcdef"


   aws_auth_users = [
    {
      userarn  = "arn:aws:iam::061473577069:user/terraform-aws-user"
      username = "terraform-backend-state-singh2311"
      groups   = ["system:masters"]
    }
  ]

}

data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_name
}

data "aws_eks_cluster_auth" "cluster" {
  name =  module.eks.cluster_name
}


# We will use ServiceAccount to connect to K8S Cluster in CI/CD mode
# ServiceAccount needs permissions to create deployments 
# and services in default namespace
resource "kubernetes_cluster_role_binding" "example" {
  metadata {
    name = "fabric8-rbac"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }
  subject {
    kind      = "ServiceAccount"
    name      = "default"
    namespace = "default"
  }

}

# Needed to set the default region
provider "aws" {
  region  = "ap-south-1"
}