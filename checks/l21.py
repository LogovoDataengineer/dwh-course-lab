"""Урок 21: нагрузка на PostgreSQL — ваши индексы под четыре запроса приложения и отчётов, без лишних индексов."""
from check import ok, pg, safe

QUERIES = {
    "q1 — последние заказы покупателя": "SELECT order_id, created_at, status, amount FROM perf.orders WHERE customer_id = 4242 ORDER BY created_at DESC LIMIT 20",
    "q2 — отчёт за день": "SELECT count(*), sum(amount) FROM perf.orders WHERE created_at::date = date '2025-12-15'",
    "q3 — вход по email": "SELECT customer_id, city FROM perf.customers WHERE lower(email) = lower('user4242@mail.ru')",
    "q4 — заказы в обработке": "SELECT order_id, customer_id, created_at FROM perf.orders WHERE status = 'processing' ORDER BY created_at LIMIT 100",
}


def check():
    n = safe(pg, "SELECT count(*) FROM perf.orders", default=None)
    ok(n == [["3000000"]], "в базе сайта есть данные урока (perf.orders — 3 миллиона заказов)", "поднимите стенд урока: make lesson-21")
    if n is None:
        return
    calls = safe(pg, "SELECT count(*) FROM pg_stat_statements WHERE query LIKE '%perf.orders%'", default=[["0"]])[0][0]
    ok(int(calls) > 0, "нагрузка запускалась, pg_stat_statements её видит", "шаг 2: bash lessons/L21/workload.sh")
    for title, sql in QUERIES.items():
        plan = "\n".join(r[0] for r in pg("EXPLAIN (ANALYZE, BUFFERS OFF, TIMING OFF) " + sql))
        seq = "Seq Scan" in plan
        ms = plan.rsplit("Execution Time: ", 1)[-1].split(" ")[0]
        ok(not seq, f"{title}: без полного чтения таблицы (выполнение {ms} мс)",
           "шаг 5: индекс под условие запроса, проверьте план через EXPLAIN ANALYZE")
    useless = pg("SELECT count(*) FROM pg_indexes WHERE schemaname = 'perf' AND indexname = 'orders_created_at_idx'")[0][0]
    ok(useless == "0", "бесполезный индекс orders_created_at_idx удалён", "DROP INDEX perf.orders_created_at_idx")
    cnt = pg("SELECT count(*) FROM pg_indexes WHERE schemaname = 'perf' AND tablename = 'orders'")[0][0]
    ok(int(cnt) <= 4, f"на таблице заказов не больше 4 индексов вместе с первичным ключом (сейчас {cnt})",
       "каждый индекс замедляет вставку: индексы — только под реальные запросы")
