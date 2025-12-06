data "terraform_remote_state" "vpc" {
  backend = "s3"

  config = {
    bucket  = "mlops-tfstate-vkuznetsov"
    key     = "vpc/terraform.tfstate"
    region  = "eu-north-1"
    profile = "default"
    encrypt = true
  }
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.10.0"

  cluster_name    = var.name
  cluster_version = var.cluster_version

  vpc_id     = data.terraform_remote_state.vpc.outputs.vpc_id
  subnet_ids = data.terraform_remote_state.vpc.outputs.private_subnet_ids

  cluster_endpoint_public_access           = true
  enable_cluster_creator_admin_permissions = true

  # Дві node group-и: CPU та "GPU" 
  eks_managed_node_groups = {
    cpu-nodes = {
      min_size     = 1
      max_size     = 3
      desired_size = 2

      instance_types = ["t3.small"]  # Free Tier
      capacity_type  = "ON_DEMAND"

      labels = {
        workload = "cpu"
      }

      tags = {
        NodeGroup = "cpu"
      }
    }

    gpu-nodes = {
      min_size     = 0
      max_size     = 2
      desired_size = 0

      instance_types = ["t3.small"]
      capacity_type  = "SPOT"

      labels = {
        workload = "gpu"
      }

      tags = {
        NodeGroup = "gpu"
      }
    }
  }

  tags = var.tags
}
