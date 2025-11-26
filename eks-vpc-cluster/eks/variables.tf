variable "name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "mlops-eks-cluster"
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "eu-north-1"
}

variable "cluster_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.29"
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    Project = "mlops-course"
    Env     = "dev"
  }
}
