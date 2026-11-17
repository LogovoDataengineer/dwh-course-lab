"""Урок 19: Greenplum — перекос по ключу распределения и ваша таблица оплат: ключ, колоночное хранение, партиции, план."""
from check import gp, ok, safe

QUERY = """EXPLAIN SELECT p.method, count(*), sum(p.amount) FROM mpp.orders o JOIN mpp.payments_opt p ON p.order_id = o.order_id
WHERE o.status = 'delivered' AND p.paid_at >= '2026-02-01' AND p.paid_at < '2026-03-01' GROUP BY p.method"""


def check():
    segs = safe(gp, "SELECT count(*) FROM gp_segment_configuration WHERE content >= 0 AND status = 'u'", default=None)
    ok(segs is not None and segs[0][0] == "2", "кластер Greenplum работает: 2 сегмента", "поднимите стенд урока: make lesson-19")
    if segs is None:
        return
    n = safe(gp, "SELECT count(*) FROM mpp.fact_sales", default=None)
    ok(n == [["3000000"]], "данные урока загружены (mpp.fact_sales — 3 миллиона продаж)", "make lesson-19")
    skew = safe(gp, "SELECT round(max(c) / avg(c), 2) FROM (SELECT count(*) AS c FROM mpp.sales_by_customer GROUP BY gp_segment_id) t", default=None)
    ok(skew is not None, f"таблица, распределённая по покупателю, создана (перекос {skew[0][0] if skew else '—'})",
       "шаг 2: make gp F=lessons/L19/skew.sql")
    dist = safe(gp, "SELECT pg_get_table_distributedby('mpp.payments_opt'::regclass)", default=None)
    ok(dist is not None, "вы создали таблицу mpp.payments_opt", "шаг 6: допишите practice/L19/payments_opt.sql и выполните make gp F=practice/L19/payments_opt.sql")
    if dist is None:
        return
    ok(dist[0][0] == "DISTRIBUTED BY (order_id)", f"ключ распределения — order_id, как у заказов ({dist[0][0]})",
       "соединение колоцировано, когда обе таблицы распределены по ключу соединения")
    parts = gp("SELECT count(*), min(partitiontablename) FROM pg_partitions WHERE schemaname = 'mpp' AND tablename = 'payments_opt'")[0]
    ok(int(parts[0]) >= 3, f"таблица разбита на партиции по месяцам (партиций: {parts[0]})", "PARTITION BY RANGE (paid_at) ... EVERY (interval '1 month')")
    if int(parts[0]) > 0:
        col = gp(f"SELECT columnstore, compresstype FROM pg_appendonly WHERE relid = 'mpp.{parts[1]}'::regclass")
        ok(col == [["t", "zstd"]], "партиции — колоночные append-optimized со сжатием zstd",
           "WITH (appendonly = true, orientation = column, compresstype = zstd)")
    same = gp("""SELECT (SELECT count(*) FROM mpp.payments_opt) = (SELECT count(*) FROM mpp.payments),
                        (SELECT sum(amount) FROM mpp.payments_opt) = (SELECT sum(amount) FROM mpp.payments)""")[0]
    ok(same == ["t", "t"], "в таблице все оплаты: число строк и сумма совпадают с mpp.payments", "INSERT INTO mpp.payments_opt SELECT * FROM mpp.payments")
    plan = "\n".join(r[0] for r in gp(QUERY))
    join_part = plan.split("Hash Join")[1] if "Hash Join" in plan else plan
    ok("Redistribute Motion" not in join_part and "Broadcast Motion" not in join_part,
       "в плане соединения нет пересылки строк между сегментами: соединение колоцированное")
    ok("Partitions selected: 1 (out of" in plan, "запрос за февраль читает одну партицию", "партиции — по paid_at, по одному месяцу")
