"""Урок 27: монитор качества загрузок — ваши проверки ловят все четыре инцидента марта и не дают ложных тревог."""
from check import ok, pg, safe

EXPECTED = {("2026-03-08", "volume"), ("2026-03-15", "null_payment_method"),
            ("2026-03-21", "duplicate_order_id"), ("2026-03-26", "negative_amount")}
NAMES = {"volume", "null_payment_method", "duplicate_order_id", "negative_amount"}


def q(sql):
    return pg(sql, db="dwh")


def check():
    n = safe(q, "SELECT count(DISTINCT order_date) FROM dq.fact_orders", default=None)
    ok(n == [["30"]], "в хранилище факт заказов за 30 дней марта", "поднимите стенд урока: make lesson-27")
    if n is None:
        return
    rows = safe(q, "SELECT check_date, check_name, failed FROM dq.daily_checks", default=None)
    ok(rows is not None, "представление dq.daily_checks создано", "шаг 3: make psql DB=dwh F=practice/L27/checks.sql")
    if rows is None:
        return
    names = {r[1] for r in rows}
    ok(names == NAMES, f"есть все четыре проверки ({', '.join(sorted(names))})",
       "проверки: duplicate_order_id, negative_amount, null_payment_method, volume")
    ok(len(rows) == 120, f"по каждой проверке — строка на каждый из 30 дней (строк {len(rows)} из 120)")
    failed = {(r[0], r[1]) for r in rows if r[2] == "t"}
    missed = EXPECTED - failed
    extra = failed - EXPECTED
    ok(not missed, "пойманы все инциденты" + (f" (пропущены: {', '.join(f'{d} {c}' for d, c in sorted(missed))})" if missed else ""),
       "сравните правило проверки с условием в practice/L27/checks.sql")
    ok(not extra, "ложных тревог нет" + (f" (лишние: {', '.join(f'{d} {c}' for d, c in sorted(extra))})" if extra else ""),
       "объём сравнивайте с медианой предыдущих 7 дней, а не с соседним днём: в выходные заказов больше")
