resource "kubernetes_namespace" "argo" {
  metadata {
    name = var.argocd_namespace
  }
}

# Встановлення Argo CD через офіційний Helm-чарт
resource "helm_release" "argo" {
  name       = "argocd"
  namespace  = kubernetes_namespace.argo.metadata[0].name

  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = var.argocd_chart_version

  recreate_pods = true
  replace       = true

  wait    = true
  timeout = 600

  values = [file("${path.module}/values/argocd-values.yaml")]

  depends_on = [
    data.aws_eks_cluster.cluster
  ]
}