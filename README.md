# MLOps Experiments

Цей репозиторій містить конфігурації та скрипти для виконання MLOps-експериментів, включно з:
- Тренуванням моделей;
- Логуванням параметрів, метрик та артефактів у **MLflow**;
- Пушингом метрик у **Prometheus PushGateway**;
- Переглядом метрик у **Grafana**.

---

## Як запустити `train_and_push.py`

### 1. Встановити залежності
```bash
pip install -r experiments/requirements.txt
```

### 2. Налаштувати port-forward

#### MLflow Tracking Server
```bash
kubectl port-forward svc/mlflow -n application 5000:5000
```

#### PushGateway
```bash
kubectl port-forward svc/pushgateway -n monitoring 9091:9091
```

### 3. Запустити скрипт тренування
```bash
python experiments/train_and_push.py
```

**Після виконання:**
- Кожен експеримент з'явиться у MLflow UI.
- Метрики `mlflow_accuracy` та `mlflow_loss` будуть доступні в Prometheus.
- Найкраща модель буде збережена у директорії `best_model/`.

---

## Як перевірити, що сервіси працюють

### MLflow (namespace: `application`)
```bash
kubectl get pods -n application | grep mlflow
kubectl get svc -n application | grep mlflow
```

### MinIO (namespace: `application`)
```bash
kubectl get pods -n application | grep minio
kubectl get svc -n application | grep minio
```

### PostgreSQL (backend MLflow, namespace: `application`)
```bash
kubectl get pods -n application | grep postgres
```

### PushGateway (namespace: `monitoring`)
```bash
kubectl get pods -n monitoring | grep pushgateway
kubectl get svc -n monitoring | grep pushgateway
```

---

## Як переглянути метрики в Grafana

### 1. Зробити port-forward для Grafana
```bash
kubectl port-forward svc/grafana -n monitoring 3000:3000
```

### 2. Відкрити Grafana
Відкрийте у браузері: [http://localhost:3000](http://localhost:3000)

### 3. Перегляд метрик
1.  Перейдіть у розділ **Explore**.
2.  Оберіть data source **Prometheus**.
3.  Виконайте запити:

    Для **accuracy**:
    ```
    mlflow_accuracy
    ```
    Для **loss**:
    ```
    mlflow_loss
    ```

[Git-репозиторій з ArgoCD Application](https://github.com/samatwa/goit-argo)
