"""Урок 25: загрузка витрины «как получилось». Работает каждый день по расписанию — пока его не попросят
перезапустить или догрузить прошлые дни. Найдите в нём две ошибки (шаги 3 и 4 практики)."""
from datetime import date, datetime, timedelta

from airflow import DAG
from airflow.providers.common.sql.operators.sql import SQLExecuteQueryOperator

with DAG(
    dag_id="l25_naive",
    schedule="@daily",
    start_date=datetime(2026, 3, 1),
    end_date=datetime(2026, 3, 14),
    catchup=False,
    tags=["урок 25"],
) as dag:
    yesterday = date.today() - timedelta(days=1)     # «вчера» — по часам машины, на которой разбирается DAG
    SQLExecuteQueryOperator(
        task_id="load_day",
        conn_id="dwh_pg",
        sql=f"""
            INSERT INTO af.naive_revenue (day, city, orders, revenue)
            SELECT created_at::date, city, count(*), sum(amount)
            FROM af.src_orders
            WHERE created_at >= '{yesterday}' AND created_at < '{yesterday}'::date + 1
            GROUP BY 1, 2
        """,
    )
