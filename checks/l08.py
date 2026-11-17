"""Урок 8: звезда в схеме mart базы dwh, сверка факта с источником, копия в ClickHouse, своё представление mart.holiday_effect."""
from check import ch, ok, pg, safe

REFERENCE = """
WITH daily AS (
  SELECT d.full_date, d.is_holiday, p.category, sum(f.amount) AS revenue
  FROM mart.fact_sales f JOIN mart.dim_date d ON d.date_key = f.date_key JOIN mart.dim_product p ON p.product_key = f.product_key
  WHERE f.status <> 'cancelled' AND f.product_key <> -1
  GROUP BY d.full_date, d.is_holiday, p.category)
SELECT category, round(avg(revenue) FILTER (WHERE is_holiday), 0), round(avg(revenue) FILTER (WHERE NOT is_holiday), 0)
FROM daily GROUP BY category ORDER BY category
"""


def q(sql):
    return pg(sql, db="dwh")


def check():
    have = {r[0] for r in safe(q, "SELECT table_name FROM information_schema.tables WHERE table_schema = 'mart'", default=[])}
    need = {"dim_date", "dim_product", "dim_customer", "fact_sales"}
    ok(need <= have, "в схеме mart есть измерения и таблица фактов", "шаги 2–3: make psql DB=dwh F=lessons/L08/dims.sql, затем fact.sql")
    if not need <= have:
        return
    unknown = q("SELECT count(*) FROM mart.dim_product WHERE product_key = -1")[0][0]
    ok(unknown == "1", "у измерения товаров есть неизвестный член -1")
    src_rows, fact_rows, diff = q("SELECT (SELECT count(*) FROM src.sales_history), (SELECT count(*) FROM mart.fact_sales), (SELECT sum(quantity * price) FROM src.sales_history) - (SELECT sum(amount) FROM mart.fact_sales)")[0]
    ok(src_rows == fact_rows and float(diff) == 0, f"факт сходится с источником: {fact_rows} строк, расхождение суммы {diff}")
    fk = q("SELECT count(*) FROM information_schema.table_constraints WHERE table_schema = 'mart' AND table_name = 'fact_sales' AND constraint_type = 'FOREIGN KEY'")[0][0]
    ok(fk == "3", f"факт ссылается на три измерения внешними ключами ({fk})")
    ch_rows = safe(ch, "SELECT count() FROM mart.fact_sales", default=[["0"]])[0][0]
    ok(ch_rows == fact_rows, f"копия звезды в ClickHouse: {ch_rows} строк факта", "шаг 5: make ch F=lessons/L08/to_clickhouse.sql")
    has = q("SELECT count(*) FROM information_schema.views WHERE table_schema = 'mart' AND table_name = 'holiday_effect'")[0][0] == "1"
    ok(has, "вы создали представление mart.holiday_effect", "шаг 6: make psql DB=dwh F=practice/L08/holiday_effect.sql")
    if has:
        cols = [r[0] for r in q("SELECT column_name FROM information_schema.columns WHERE table_schema = 'mart' AND table_name = 'holiday_effect' ORDER BY ordinal_position")]
        ok(cols == ["category", "holiday_avg", "regular_avg"], f"столбцы category, holiday_avg, regular_avg (сейчас: {', '.join(cols)})", "переименуйте столбцы через AS")
        if cols == ["category", "holiday_avg", "regular_avg"]:
            ok(q("SELECT category, holiday_avg, regular_avg FROM mart.holiday_effect ORDER BY category") == q(REFERENCE),
               "средние совпадают с эталоном",
               "сначала сумма по дню и категории, потом среднее по дням; без отмен и без неизвестного товара; round(..., 0)")
