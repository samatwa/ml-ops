import mlflow
import mlflow.sklearn
from sklearn.datasets import load_iris
from sklearn.model_selection import train_test_split
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import accuracy_score, log_loss
from prometheus_client import CollectorRegistry, Gauge, push_to_gateway
import numpy as np
import os
import shutil
from dotenv import load_dotenv

load_dotenv()

# MLflow and PushGateway configuration
MLFLOW_TRACKING_URI = os.getenv("MLFLOW_TRACKING_URI")
PUSHGATEWAY_URL = os.getenv("PUSHGATEWAY_URL")
EXPERIMENT_NAME = os.getenv("EXPERIMENT_NAME")

mlflow.set_tracking_uri(MLFLOW_TRACKING_URI)
mlflow.set_experiment(EXPERIMENT_NAME)


def train_and_push():
    # Load dataset
    iris = load_iris()
    X_train, X_test, y_train, y_test = train_test_split(
        iris.data, iris.target, test_size=0.2, random_state=42
    )

    # Training parameters
    learning_rates = [0.01, 0.1, 0.5]
    epochs = [100, 200]

    for lr in learning_rates:
        for epoch in epochs:
            with mlflow.start_run() as run:
                run_id = run.info.run_id
                print(f"Starting run {run_id} with lr={lr} and epochs={epoch}")

                # Log parameters
                mlflow.log_param("learning_rate", lr)
                mlflow.log_param("epochs", epoch)

                # Train model
                model = LogisticRegression(
                    solver="liblinear", multi_class="auto", C=1.0 / lr, max_iter=epoch
                )
                model.fit(X_train, y_train)

                # Make predictions
                y_pred = model.predict(X_test)
                y_pred_proba = model.predict_proba(X_test)

                # Calculate metrics
                accuracy = accuracy_score(y_test, y_pred)
                loss = log_loss(y_test, y_pred_proba)

                # Log metrics
                mlflow.log_metric("accuracy", accuracy)
                mlflow.log_metric("loss", loss)

                # Save model as artifact
                mlflow.sklearn.log_model(model, "model")

                # Push metrics to PushGateway
                registry = CollectorRegistry()
                g_accuracy = Gauge(
                    "mlflow_accuracy",
                    "Accuracy of the model",
                    ["run_id"],
                    registry=registry,
                )
                g_loss = Gauge(
                    "mlflow_loss", "Loss of the model", ["run_id"], registry=registry
                )

                g_accuracy.labels(run_id=run_id).set(accuracy)
                g_loss.labels(run_id=run_id).set(loss)

                try:
                    push_to_gateway(
                        PUSHGATEWAY_URL, job="mlflow_metrics", registry=registry
                    )
                    print(
                        f"Successfully pushed metrics for run {run_id} to PushGateway."
                    )
                except Exception as e:
                    print(
                        f"Failed to push metrics for run {run_id} to PushGateway: {e}"
                    )

    # Find the best run
    best_run = mlflow.search_runs(order_by=["metrics.accuracy DESC"]).iloc[0]
    best_run_id = best_run.run_id
    best_model_uri = f"runs:/{best_run_id}/model"
    print(f"Best run found: {best_run_id} with accuracy: {best_run.metrics_accuracy}")

    # Copy the best model to a local directory
    best_model_path = "best_model"
    if os.path.exists(best_model_path):
        shutil.rmtree(best_model_path)
    os.makedirs(best_model_path)

    mlflow.sklearn.load_model(best_model_uri, dst_path=best_model_path)
    print(f"Best model copied to {best_model_path}/")


if __name__ == "__main__":
    train_and_push()
