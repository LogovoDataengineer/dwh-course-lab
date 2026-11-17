"""Урок 5: хранилище по слоям, несколько загрузок, сверка слоёв и своя витрина cdm.city_sales."""
from check import ok, pg, safe

REFERENCE = """
SELECT coalesce(c.city, 'неизвестно'), count(*), coalesce(sum(o.amount) FILTER (WHERE o.status <> 'cancelled'), 0)
FROM dds.orders o LEFT JOIN dds.customer c ON c.customer_key = o.customer_key
GROUP BY 1 ORDER BY 1
"""


def q(sql):
    return pg(sql, db="dwh")


def check():
    batches = safe(q, "SELECT count(*), count(*) FILTER (WHERE finished_at IS NOT NULL) FROM meta.load_log", default=None)
    ok(batches is not None, "в базе dwh есть слои и журнал загрузок", "поднимите стенд урока: make lesson-05")
    if batches is None:
        return
    total, done = map(int, batches[0])
    ok(done >= 3, f"в журнале не меньше трёх завершённых загрузок (сейчас {done})", "запустите несколько часов: bash lessons/L05/hour.sh")
    ok(total == done, "все загрузки в журнале завершены", "последняя загрузка упала — посмотрите её вывод и запустите hour.sh ещё раз")
    if done == 0:
        return
    multi = q("SELECT count(*) FROM (SELECT order_id FROM stg.orders_raw GROUP BY order_id HAVING count(*) > 1) t")[0][0]
    ok(int(multi) > 0, f"в STG один и тот же заказ лежит несколько раз ({multi} заказов пришли повторно)")
    stg_orders, ods_orders, rejected = map(int, q("SELECT (SELECT count(DISTINCT order_id) FROM stg.orders_raw), (SELECT count(*) FROM ods.orders), (SELECT count(*) FROM ods.orders_rejected)")[0])
    ok(stg_orders == ods_orders + rejected, f"сверка STG и ODS: {stg_orders} заказов = {ods_orders} в ODS + {rejected} в отбраковке")
    cdm, ods = q("SELECT (SELECT sum(revenue) FROM cdm.daily_sales), (SELECT sum(amount) FROM ods.orders WHERE status <> 'cancelled')")[0]
    ok(cdm == ods, f"сверка ODS и витрины: выручка {cdm} в обоих слоях")
    has = q("SELECT count(*) FROM information_schema.tables WHERE table_schema = 'cdm' AND table_name = 'city_sales'")[0][0] == "1"
    ok(has, "вы создали витрину cdm.city_sales", "шаг 6: make psql DB=dwh F=practice/L05/city_sales.sql")
    if has:
        cols = [r[0] for r in q("SELECT column_name FROM information_schema.columns WHERE table_schema = 'cdm' AND table_name = 'city_sales' ORDER BY ordinal_position")]
        ok(cols == ["city", "orders", "revenue"], f"столбцы city, orders, revenue (сейчас: {', '.join(cols)})", "переименуйте столбцы через AS")
        if cols == ["city", "orders", "revenue"]:
            mine = q("SELECT city, orders, revenue FROM cdm.city_sales ORDER BY city")
            ok(mine == q(REFERENCE), "города, заказы и выручка совпадают с данными DDS",
               "заказы без покупателя — город «неизвестно»; отмены не входят в выручку; пересоздайте витрину после последней загрузки")
