module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.10.0"

  cluster_name    = var.name
  cluster_version = "1.29"

  vpc_id     = var.vpc_id
  subnet_ids = var.private_subnet_ids

  eks_managed_node_groups = {
    cpu-nodes = {
      min_size     = 1
      max_size     = 3
      desired_size = 2

      instance_types = ["t3.medium"]
    }

    gpu-nodes = {
      min_size     = 0
      max_size     = 2
      desired_size = 0

      instance_types = ["g4dn.xlarge"]
      capacity_type  = "SPOT"
    }
  }

  tags = var.tags
}
