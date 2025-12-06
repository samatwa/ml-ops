# Вивід початкового пароля адміністратора Argo CD (в форматі Base64)
output "argocd_initial_admin_password_base64" {
  description = "The initial admin password for Argo CD, base64 encoded."
  value       = data.kubernetes_secret.argocd_initial_admin_secret.data.password
  sensitive   = true
}

# Вивід інструкції для доступу до Argo CD
output "argocd_server_access_instructions" {
  description = "Instructions to access the Argo CD server."
  value = <<-EOT
To access the Argo CD UI, run the following command:
kubectl port-forward svc/argocd-server -n ${kubernetes_namespace.argo.metadata[0].name} 8080:443

Then, open a browser and go to: https://localhost:8080

Login with the username 'admin'.

To get the password, run the following command in your terminal:
echo "<PASSWORD_FROM_OUTPUT>" | base64 --decode
(Replace <PASSWORD_FROM_OUTPUT> with the value from the 'argocd_initial_admin_password_base64' output)
EOT
}