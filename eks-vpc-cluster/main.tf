module "vpc" {
  source = "./vpc"

  # Якщо хочеш — можна явно прокидати змінні, інакше модуль візьме дефолти:
  # aws_region         = "eu-north-1"
  # vpc_cidr           = "10.0.0.0/16"
  # availability_zones = ["eu-north-1a", "eu-north-1b", "eu-north-1c"]
}

module "eks" {
  source = "./eks"

  # name            = "mlops-eks-cluster"
  # region          = "eu-north-1"
  # cluster_version = "1.29"
}
