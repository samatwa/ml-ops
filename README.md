# goit-argo

Цей репозиторій містить конфігураційні файли Kubernetes для розгортання додатків за допомогою ArgoCD.

## Початок роботи

### 1. Розгортання інфраструктури

Для розгортання EKS кластера та встановлення ArgoCD виконайте наступні кроки у репозиторії `ml-ops`:

```bash
# Ініціалізація Terraform
terraform init

# Застосування конфігурації
terraform apply
```

### 2. Перевірка роботи ArgoCD

Після успішного виконання `terraform apply`, переконайтесь, що ArgoCD працює:

```bash
# Перевірка подів ArgoCD
kubectl get pods -n argocd
```

### 3. Доступ до ArgoCD UI

Щоб отримати доступ до веб-інтерфейсу ArgoCD, виконайте port-forward та отримайте пароль:

```bash
# Port-forward для доступу до UI
kubectl port-forward svc/argocd-server -n argocd 8080:80

# Отримання пароля для користувача admin
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

Після цього відкрийте `https://localhost:8080` у вашому браузері. Логін - `admin`.

### 4. Перевірка розгортання додатку

ArgoCD автоматично синхронізує додаток, описаний у `application.yaml` з цього репозиторію.

Перевірте статус додатку в UI ArgoCD або через `kubectl`:

```bash
# Перевірка статусу ArgoCD Application
kubectl get applications -n argocd

# Перевірка подів nginx у неймспейсі application
kubectl get pods -n application
```

### 5. Доступ до NGINX

Сервіс NGINX налаштований з типом `LoadBalancer`. Щоб отримати доступ, знайдіть його зовнішню IP-адресу:

```bash
kubectl get svc -n application
```

Знайдіть сервіс `nginx-application` та використовуйте його `EXTERNAL-IP` для доступу.

### Посилання

*   [Git-репозиторій з ArgoCD Application](https://github.com/samatwa/goit-argo)
