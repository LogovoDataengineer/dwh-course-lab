"""Урок 25, шаг 5 (ваш): DAG daily_revenue — витрина af.daily_revenue (выручка по дням и городам).

Требования:
  1) день загрузки — логическая дата запуска, а не «сегодня»: в SQL используйте шаблон {{ ds }}
     (или {{ data_interval_start }} / {{ data_interval_end }}) — Airflow подставит его сам при каждом запуске;
  2) загрузка дня идемпотентна: повторный запуск того же дня не задваивает строки
     (удалить день и вставить заново в одной транзакции);
  3) после загрузки — проверка: SQLCheckOperator, что за день в витрине есть строки и число заказов
     совпадает с источником (af.src_orders); упавшая проверка — упавший запуск;
  4) расписание @daily c 1 по 14 марта 2026 года, catchup=True, max_active_runs=1.
Подключение к хранилищу — conn_id="dwh_pg". Образец SQL загрузки — в DAG l25_naive (без его ошибок).
Файл подхватывается Airflow за 20 секунд; ошибки разбора видны вверху страницы DAGs в веб-интерфейсе.
"""
from datetime import datetime

from airflow import DAG
from airflow.providers.common.sql.operators.sql import SQLCheckOperator, SQLExecuteQueryOperator

with DAG(
    dag_id="daily_revenue",
    schedule="@daily",
    start_date=datetime(2026, 3, 1),
    end_date=datetime(2026, 3, 14),
    catchup=False,          # ЗАДАНИЕ: нужно догнать все дни с 1 по 14 марта
    tags=["урок 25"],
) as dag:
    # ЗАДАНИЕ: задача load_day (SQLExecuteQueryOperator) и задача check_day (SQLCheckOperator), load_day >> check_day
    pass
