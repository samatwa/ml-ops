terraform {
  backend "s3" {
    bucket         = "mlops-tfstate-vkuznetsov"
    key            = "eks/terraform.tfstate"
    region         = "eu-north-1"
    profile        = "default"
  }
}