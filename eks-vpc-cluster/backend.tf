terraform {
 backend "s3" {
  bucket = "mlops-tfstate-vkuznetsov"
  key  = "global/s3/terraform.tfstate"
  region = "eu-north-1"
  profile = "default"
 }
}