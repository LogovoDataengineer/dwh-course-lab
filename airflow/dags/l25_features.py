"""Урок L25: возможности Airflow — динамические задачи, группы задач, XCom, правила запуска, повторы."""
from datetime import datetime, timedelta

from airflow.decorators import dag, task, task_group
from airflow.operators.empty import EmptyOperator
from airflow.utils.trigger_rule import TriggerRule

TABLES = ["customers", "orders", "order_items", "payments"]


@dag(
    dag_id="l25_features",
    start_date=datetime(2026, 3, 1),
    schedule="0 3 * * *",
    catchup=False,
    max_active_runs=1,
    default_args={"retries": 2, "retry_delay": timedelta(minutes=5)},
    tags=["урок 25"],
)
def l25_features():
    @task
    def list_tables():
        return TABLES                      # маленькое значение — уходит в XCom

    @task
    def extract(table: str, ds=None):
        rows = {"customers": 12, "orders": 40, "order_items": 75, "payments": 40}[table]
        print(f"extract {table} за {ds}: {rows} строк")
        return {"table": table, "rows": rows}

    @task_group(group_id="checks")
    def checks(results):
        @task
        def row_counts(results):
            total = sum(r["rows"] for r in results)
            print(f"всего строк: {total}")
            return total

        @task
        def not_empty(results):
            empty = [r["table"] for r in results if r["rows"] == 0]
            if empty:
                raise ValueError(f"пустые таблицы: {empty}")
            print("пустых таблиц нет")

        row_counts(results)
        not_empty(results)

    @task(trigger_rule=TriggerRule.ALL_DONE)
    def notify(ds=None):
        print(f"загрузка за {ds} завершена, отчёт отправлен")

    done = EmptyOperator(task_id="done")

    extracted = extract.expand(table=list_tables())    # динамическое число задач
    checks(extracted) >> notify() >> done


l25_features()
