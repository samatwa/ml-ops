# MLOps Experiments

This repository contains scripts and configurations for MLOps experiments, including model training, metric logging with MLflow, and monitoring with Prometheus and Grafana.

## How to Run `train_and_push.py`

1.  **Install dependencies:**
    ```bash
    pip install -r experiments/requirements.txt
    ```

2.  **Set up port forwarding for MLflow and PushGateway:**

    *   **MLflow:**
        ```bash
        kubectl port-forward svc/mlflow -n infra-tools 5000:5000
        ```
    *   **PushGateway:**
        ```bash
        kubectl port-forward svc/pushgateway -n monitoring 9091:9091
        ```

3.  **Run the script:**
    ```bash
    python experiments/train_and_push.py
    ```

## How to Check MLflow and PushGateway in the Cluster

*   **MLflow:**
    ```bash
    kubectl get pods -n infra-tools | grep mlflow
    ```
*   **PushGateway:**
    ```bash
    kubectl get pods -n monitoring | grep pushgateway
    ```

## How to View Metrics in Grafana

1.  **Port-forward Grafana:**
    ```bash
    kubectl port-forward svc/grafana -n monitoring 3000:3000
    ```
2.  Open Grafana in your browser at `http://localhost:3000`.
3.  Go to **Explore** and select the **Prometheus** data source.
4.  Query for `mlflow_accuracy` or `mlflow_loss` to see the metrics.

## Screenshots

*   **MLflow UI:**
    ![MLflow UI](screenshots/mlflow-ui.png)

*   **Grafana Explore:**
    ![Grafana Explore](screenshots/grafana-explore.png)
