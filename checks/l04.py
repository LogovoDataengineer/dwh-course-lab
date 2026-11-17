"""Урок 4: дедупликация событий, сессии, покупки по дням и своё представление reports.second_purchase."""
from check import ok, pg, safe

REFERENCE = """
WITH p AS (
  SELECT customer_id, city, sold_at,
         row_number() OVER w AS rn,
         lead(sold_at) OVER w AS next_at
  FROM sales_history WHERE status <> 'cancelled'
  WINDOW w AS (PARTITION BY customer_id ORDER BY sold_at, sale_id))
SELECT city, count(*), round(avg(extract(epoch FROM next_at - sold_at) / 86400)::numeric, 1)
FROM p WHERE rn = 1 AND next_at IS NOT NULL GROUP BY city ORDER BY city
"""


def exists(kind, schema, name):
    table = "views" if kind == "view" else "tables"
    r = safe(pg, f"SELECT count(*) FROM information_schema.{table} WHERE table_schema = '{schema}' AND table_name = '{name}'", default=[["0"]])
    return r[0][0] == "1"


def check():
    clean = exists("table", "public", "app_events_clean")
    ok(clean, "есть таблица app_events_clean без повторов", "выполните шаг 2: make psql F=lessons/L04/windows.sql")
    if clean:
        raw, uniq, rows = pg("SELECT (SELECT count(*) FROM app_events), (SELECT count(DISTINCT event_id) FROM app_events), (SELECT count(*) FROM app_events_clean)")[0]
        ok(rows == uniq, f"в ней каждое событие один раз: {rows} из {raw} строк сырого журнала", "оставьте одну строку на event_id: row_number() ... = 1")
    for name in ("sessions", "daily_purchases"):
        ok(exists("view", "reports", name), f"есть представление reports.{name}", "выполните шаг 2: make psql F=lessons/L04/windows.sql")
    has = exists("view", "reports", "second_purchase")
    ok(has, "вы создали представление reports.second_purchase", "шаг 5: make psql F=practice/L04/second_purchase.sql")
    if has:
        cols = [r[0] for r in pg("SELECT column_name FROM information_schema.columns WHERE table_schema = 'reports' AND table_name = 'second_purchase' ORDER BY ordinal_position")]
        ok(cols == ["city", "customers", "avg_days"], f"столбцы city, customers, avg_days (сейчас: {', '.join(cols)})", "переименуйте столбцы через AS")
        if cols == ["city", "customers", "avg_days"]:
            mine = pg("SELECT city, customers, avg_days FROM reports.second_purchase ORDER BY city")
            ok(mine == pg(REFERENCE), "города, число покупателей и средний разрыв совпадают с эталоном",
               "город — первой покупки; покупки по времени, при равном времени — по sale_id; отмены не считаются; дни — с дробной частью, округление до 0,1")
