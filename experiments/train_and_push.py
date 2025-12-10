import os
import shutil

from dotenv import load_dotenv

import mlflow
import mlflow.sklearn
from mlflow.artifacts import download_artifacts

from sklearn.datasets import load_iris
from sklearn.model_selection import train_test_split
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import accuracy_score, log_loss

from prometheus_client import CollectorRegistry, Gauge, push_to_gateway

# Загружаем .env из текущей директории
load_dotenv()

# MLflow and PushGateway configuration
MLFLOW_TRACKING_URI = os.getenv("MLFLOW_TRACKING_URI", "http://localhost:5000")
PUSHGATEWAY_URL = os.getenv("PUSHGATEWAY_URL", "localhost:9091")
EXPERIMENT_NAME = os.getenv("EXPERIMENT_NAME", "iris-logreg-pushgateway")

if not MLFLOW_TRACKING_URI:
    raise ValueError("MLFLOW_TRACKING_URI is not set")
if not PUSHGATEWAY_URL:
    raise ValueError("PUSHGATEWAY_URL is not set")

mlflow.set_tracking_uri(MLFLOW_TRACKING_URI)
mlflow.set_experiment(EXPERIMENT_NAME)


def train_and_push():
    # 1. Загружаем датасет Iris
    iris = load_iris()
    X_train, X_test, y_train, y_test = train_test_split(
        iris.data, iris.target, test_size=0.2, random_state=42
    )

    # 2. Сетка гиперпараметров
    learning_rates = [0.01, 0.1, 0.5]
    epochs = [100, 200]

    for lr in learning_rates:
        for epoch in epochs:
            with mlflow.start_run() as run:
                run_id = run.info.run_id
                print(f"Starting run {run_id} with lr={lr} and epochs={epoch}")

                # Логируем параметры
                mlflow.log_param("learning_rate", lr)
                mlflow.log_param("epochs", epoch)

                # Обучаем модель
                model = LogisticRegression(
                    solver="liblinear",
                    multi_class="auto",
                    C=1.0 / lr,
                    max_iter=epoch,
                )
                model.fit(X_train, y_train)

                # Предсказания
                y_pred = model.predict(X_test)
                y_pred_proba = model.predict_proba(X_test)

                # Метрики
                accuracy = accuracy_score(y_test, y_pred)
                loss = log_loss(y_test, y_pred_proba)

                # Логируем метрики в MLflow
                mlflow.log_metric("accuracy", accuracy)
                mlflow.log_metric("loss", loss)

                # Логируем модель как артефакт
                mlflow.sklearn.log_model(model, "model")

                # Пушим метрики в PushGateway
                registry = CollectorRegistry()
                g_accuracy = Gauge(
                    "mlflow_accuracy",
                    "Accuracy of the model",
                    ["run_id"],
                    registry=registry,
                )
                g_loss = Gauge(
                    "mlflow_loss",
                    "Loss of the model",
                    ["run_id"],
                    registry=registry,
                )

                g_accuracy.labels(run_id=run_id).set(accuracy)
                g_loss.labels(run_id=run_id).set(loss)

                try:
                    push_to_gateway(
                        PUSHGATEWAY_URL,
                        job="mlflow_metrics",
                        registry=registry,
                    )
                    print(
                        f"Successfully pushed metrics for run {run_id} to PushGateway."
                    )
                except Exception as e:
                    print(
                        f"Failed to push metrics for run {run_id} to PushGateway: {e}"
                    )

    # 3. Находим лучший run по accuracy
    runs_df = mlflow.search_runs(
        order_by=["metrics.accuracy DESC"],
        max_results=1,
    )
    if runs_df.empty:
        raise RuntimeError("No runs found in MLflow experiment")

    best_run = runs_df.iloc[0]
    best_run_id = best_run.run_id
    best_accuracy = best_run["metrics.accuracy"]

    print(f"Best run found: {best_run_id} with accuracy: {best_accuracy:.4f}")

    # 4. Копируем лучшую модель в локальную директорию best_model/
    best_model_path = "best_model"
    if os.path.exists(best_model_path):
        shutil.rmtree(best_model_path)

    # Скачиваем артефакт "model" этого run'а
    local_model_dir = download_artifacts(
        run_id=best_run_id,
        artifact_path="model",
    )

    shutil.copytree(local_model_dir, best_model_path)
    print(f"Best model copied to {best_model_path}/")


if __name__ == "__main__":
    train_and_push()
