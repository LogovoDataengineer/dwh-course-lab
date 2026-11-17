"""Урок 20: ClickHouse — словарь из PostgreSQL, ReplacingMergeTree, ваши предагрегаты в AggregatingMergeTree через MV."""
from check import ch, ok, safe

RAW = """SELECT toDate(sold_at) AS day, dictGet('shop.products_dict', 'category', toUInt64(product_id)) AS category,
                sum(amount) AS revenue, uniqHLL12(customer_id) AS buyers
         FROM shop.sales GROUP BY day, category"""
MV = "SELECT day, category, sum(revenue) AS revenue, uniqHLL12Merge(buyers) AS buyers FROM shop.sales_daily GROUP BY day, category"


def check():
    n = safe(ch, "SELECT count() FROM shop.sales", default=None)
    ok(n is not None and int(n[0][0]) >= 20000000, f"в ClickHouse есть продажи урока ({n[0][0] if n else 0})", "поднимите стенд урока: make lesson-20")
    if n is None:
        return
    d = safe(ch, "SELECT status, element_count FROM system.dictionaries WHERE database = 'shop' AND name = 'products_dict'", default=[])
    ok(d and d[0][0] == "LOADED" and d[0][1] == "5000", "словарь shop.products_dict загружен из PostgreSQL (5000 товаров)",
       "шаг 2: make ch F=lessons/L20/dictionary.sql")
    st = ch("SELECT count(), uniqExact(order_id), (SELECT count() FROM system.parts WHERE database = 'shop' AND table = 'order_status' AND active) FROM shop.order_status")[0]
    ok(st[0] == st[1], f"статусы заказов схлопнуты слиянием: строк {st[0]}, заказов {st[1]}", "шаг 4: make ch Q=\"SYSTEM START MERGES shop.order_status\", затем make ch Q=\"OPTIMIZE TABLE shop.order_status FINAL\"")
    eng = safe(ch, "SELECT engine FROM system.tables WHERE database = 'shop' AND name = 'sales_daily'", default=[])
    ok(eng == [["AggregatingMergeTree"]], f"таблица shop.sales_daily на движке AggregatingMergeTree ({eng[0][0] if eng else 'нет'})",
       "шаг 5: допишите practice/L20/sales_daily.sql и выполните make ch F=practice/L20/sales_daily.sql")
    if not eng:
        return
    types = dict(ch("SELECT name, type FROM system.columns WHERE database = 'shop' AND table = 'sales_daily'"))
    ok(types.get("buyers") == "AggregateFunction(uniqHLL12, UInt32)" and "revenue" in types and "day" in types and "category" in types,
       "столбцы day, category, revenue и buyers — состояние uniqHLL12", "buyers AggregateFunction(uniqHLL12, UInt32)")
    mv = ch("SELECT count() FROM system.tables WHERE database = 'shop' AND engine = 'MaterializedView' AND create_table_query LIKE '%TO shop.sales_daily%'")[0][0]
    ok(mv == "1", "материализованное представление пишет в shop.sales_daily", "CREATE MATERIALIZED VIEW shop.sales_daily_mv TO shop.sales_daily AS ...")
    apr = ch("SELECT count() FROM shop.sales WHERE toDate(sold_at) = '2026-04-01'")[0][0]
    ok(apr == "200000", f"новые продажи 1 апреля вставлены ({apr})", "шаг 7: make ch F=lessons/L20/new_sales.sql")
    if "revenue" not in types or "buyers" not in types:
        return
    rev = ch(f"SELECT count() FROM (SELECT day, category, revenue FROM ({MV}) EXCEPT SELECT day, category, revenue FROM ({RAW}))")[0][0]
    days = ch(f"SELECT (SELECT count() FROM ({MV})), (SELECT count() FROM ({RAW}))")[0]
    ok(rev == "0" and days[0] == days[1], f"выручка в предагрегатах совпадает с продажами по всем дням и категориям (расхождений: {rev})",
       "старые строки перенесите один раз, новые приходят через MV: двойной перенос удвоит выручку")
    buy = ch(f"SELECT count() FROM (SELECT day, category, buyers FROM ({MV}) EXCEPT SELECT day, category, buyers FROM ({RAW}))")[0][0]
    ok(buy == "0", f"число покупателей из состояний совпадает с uniqHLL12 по продажам (расхождений: {buy})")
    ch("SYSTEM FLUSH LOGS")
    rr = ch("SELECT read_rows FROM system.query_log WHERE type = 'QueryFinish' AND log_comment = 'dashboard_mv' ORDER BY event_time DESC LIMIT 1")
    ok(bool(rr) and int(rr[0][0]) < 100000, f"запрос дашборда по предагрегатам читает {rr[0][0] if rr else '—'} строк вместо 20 миллионов",
       "шаг 6: make ch F=lessons/L20/dashboard_mv.sql")
