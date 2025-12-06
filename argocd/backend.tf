terraform {
 backend "s3" {
  bucket = "mlops-tfstate-vkuznetsov"
  key   = "argocd/terraform.tfstate"
  region = "eu-north-1"
  profile = "default"
 }
}