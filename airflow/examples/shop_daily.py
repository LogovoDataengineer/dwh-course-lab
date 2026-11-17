"""Ежедневная загрузка хранилища магазина: проверить источник, снять SCD2-снимок, собрать и проверить витрины dbt."""
from datetime import datetime, timedelta

from airflow import DAG
from airflow.operators.bash import BashOperator
from airflow.providers.common.sql.operators.sql import SQLCheckOperator

DBT = "cd /opt/dbt_shop && dbt --no-use-colors"   # путь к проекту dbt на машине, где работает Airflow

default_args = {
    "owner": "dwh",
    "retries": 2,                          # повторить упавшую задачу дважды
    "retry_delay": timedelta(minutes=5),
}

with DAG(
    dag_id="shop_daily",
    description="STG -> витрины магазина: проверки, snapshot, dbt build",
    schedule="0 3 * * *",                  # каждый день в 03:00 UTC
    start_date=datetime(2026, 3, 1),
    catchup=False,                         # не догонять пропущенные дни при включении
    max_active_runs=1,                     # не запускать два дня параллельно
    default_args=default_args,
    tags=["dwh", "dbt"],
) as dag:
    source_has_orders = SQLCheckOperator(
        task_id="source_has_orders",
        conn_id="shop_db",
        # {{ ds }} — дата интервала запуска: проверяем, что за этот день в источнике есть заказы
        sql="SELECT count(*) > 0 FROM orders WHERE created_at::date <= '{{ ds }}'",
    )
    dbt_snapshot = BashOperator(task_id="dbt_snapshot", bash_command=f"{DBT} snapshot")
    dbt_build = BashOperator(task_id="dbt_build", bash_command=f"{DBT} build --exclude resource_type:snapshot")

    source_has_orders >> dbt_snapshot >> dbt_build
