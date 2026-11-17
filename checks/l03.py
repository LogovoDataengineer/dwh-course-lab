"""Урок 3: представления отчёта директору и своё представление reports.top_products (top-3 товара в каждой категории)."""
from check import ok, pg, safe

REFERENCE = """
SELECT category, product_id, revenue, place FROM (
  SELECT category, product_id, sum(quantity * price) AS revenue,
         row_number() OVER (PARTITION BY category ORDER BY sum(quantity * price) DESC, product_id) AS place
  FROM sales_history WHERE status <> 'cancelled' GROUP BY category, product_id) t
WHERE place <= 3 ORDER BY category, place
"""


def view_exists(name):
    r = safe(pg, f"SELECT count(*) FROM information_schema.views WHERE table_schema = 'reports' AND table_name = '{name}'", default=[["0"]])
    return r[0][0] == "1"


def check():
    for name, step in (("city_month", "шаг 2"), ("category_rollup", "шаг 2"), ("city_check", "шаг 2")):
        ok(view_exists(name), f"есть представление reports.{name}", f"выполните {step}: make psql F=lessons/L03/report.sql")
    if view_exists("category_rollup"):
        total = pg("SELECT revenue FROM reports.category_rollup WHERE quarter = 'Весь год' AND category = 'Все категории'")
        expected = pg("SELECT sum(quantity * price) FROM sales_history WHERE status <> 'cancelled'")[0][0]
        ok(total and total[0][0] == expected, "общий итог ROLLUP совпадает с выручкой за год", "проверьте GROUP BY ROLLUP (quarter, category)")
    has = view_exists("top_products")
    ok(has, "вы создали представление reports.top_products", "шаг 5: выполните make psql F=practice/L03/top_products.sql")
    if has:
        cols = [r[0] for r in pg("SELECT column_name FROM information_schema.columns WHERE table_schema = 'reports' AND table_name = 'top_products' ORDER BY ordinal_position")]
        ok(cols == ["category", "product_id", "revenue", "place"], f"столбцы category, product_id, revenue, place (сейчас: {', '.join(cols)})",
           "переименуйте столбцы через AS, порядок важен")
        if cols == ["category", "product_id", "revenue", "place"]:
            mine = pg("SELECT category, product_id, revenue, place FROM reports.top_products ORDER BY category, place")
            ref = pg(REFERENCE)
            ok(len(mine) == 15, f"по 3 товара в каждой из 5 категорий (строк: {len(mine)})", "в каждой категории ровно три строки: LIMIT 3 внутри LATERAL")
            ok(mine == ref, "товары, выручка и места совпадают с эталоном",
               "отмены не входят в выручку; места — по убыванию выручки, при равной выручке выше товар с меньшим номером")
