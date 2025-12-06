data "terraform_remote_state" "eks" {
  backend = "s3"
  config = {
    bucket  = var.eks_state_bucket
    key     = var.eks_state_key
    region  = var.eks_state_region
    profile = var.aws_profile
  }
}


# Дані про EKS для провайдерів
data "aws_eks_cluster" "cluster" {
  name = data.terraform_remote_state.eks.outputs.cluster_name
}


data "aws_eks_cluster_auth" "cluster" {
  name = data.terraform_remote_state.eks.outputs.cluster_name
}

# Отримання секрету з початковим паролем адміністратора Argo CD
data "kubernetes_secret" "argocd_initial_admin_secret" {
  metadata {
    name      = "argocd-initial-admin-secret"
    namespace = kubernetes_namespace.argo.metadata[0].name
  }

  # Це гарантує, що ми будемо шукати секрет тільки після того,
  # як Helm-чарт буде успішно встановлений
  depends_on = [helm_release.argo]
}