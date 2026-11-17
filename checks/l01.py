"""Урок 1: история продаж скопирована в ClickHouse и совпадает с базой сайта."""
from check import ch, ok, pg, safe


def check():
    pg_rows, pg_revenue = pg("SELECT count(*), sum(quantity * price) FROM sales_history")[0]
    ok(int(pg_rows) == 5_000_000, f"в базе сайта sales_history 5 000 000 строк (сейчас {pg_rows})", "запустите make lesson-01")
    ch_db = safe(ch, "SELECT count() FROM system.tables WHERE database = 'dwh' AND name = 'sales_history'", default=[["0"]])
    ok(ch_db[0][0] == "1", "в ClickHouse есть таблица dwh.sales_history", "выполните шаг 4: lessons/L01/to_clickhouse.sql")
    if ch_db[0][0] == "1":
        ch_rows, ch_revenue = ch("SELECT count(), sum(quantity * price) FROM dwh.sales_history")[0]
        ok(ch_rows == pg_rows, f"в хранилище столько же строк, сколько в базе сайта ({ch_rows})",
           "скопируйте таблицу заново: повторный запуск to_clickhouse.sql пересоздаёт её")
        ok(float(ch_revenue) == float(pg_revenue), f"выручка в хранилище совпадает с базой сайта ({float(ch_revenue):,.0f} ₽)".replace(",", " "),
           "данные скопированы не полностью — пересоздайте таблицу")
        engine = ch("SELECT engine, sorting_key FROM system.tables WHERE database = 'dwh' AND name = 'sales_history'")[0]
        ok(engine[0] == "MergeTree", f"таблица хранилища — колоночная MergeTree, порядок строк ({engine[1]})")
