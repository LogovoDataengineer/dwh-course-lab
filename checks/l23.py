"""Урок 23: Iceberg — откат плохих загрузок к хорошему снимку и правильная догрузка; таблица совпадает с эталоном."""
from check import ch, ok, run, safe


def trino(sql):
    out = run("trino", "trino", "--output-format", "TSV", "--execute", sql)
    return [line.split("\t") for line in out.splitlines() if line and not line.startswith("WARNING")]


def check():
    snaps = safe(trino, 'SELECT count(*), count_if(NOT h.is_current_ancestor) FROM iceberg.shop."orders$history" h', default=None)
    ok(snaps is not None and int(snaps[0][0]) >= 6, f"таблица Iceberg lake.shop.orders прошла загрузки (снимков в истории: {snaps[0][0] if snaps else 0})",
       "шаги 2–3: make lesson-23, затем bash lessons/L23/load.sh 2026-03-01 2026-03-03 и загрузка дней 4–5 новой версией задания")
    if snaps is None:
        return
    ok(int(snaps[0][1]) >= 2, f"плохие снимки откачены: в истории, но не в текущей цепочке ({snaps[0][1]})",
       "шаг 5: make spark F=\"practice/L23/rollback.py <снимок после 3 марта>\"")
    cur = {r[0]: (int(r[1]), float(r[2])) for r in trino("SELECT status, count(*), sum(amount) FROM iceberg.shop.orders GROUP BY status")}
    exp = {r[0]: (int(r[1]), float(r[2])) for r in ch("SELECT status, orders, revenue FROM s3('http://minio:9000/lake/l23/expected/*.parquet', 'dwhadmin', 'dwh-admin-123', 'Parquet')")}
    total = sum(v[0] for v in cur.values())
    ok(total == sum(v[0] for v in exp.values()), f"в таблице {total} заказов — как после правильной загрузки всех пяти дней",
       "после отката загрузите дни 4 и 5 правильным заданием: bash lessons/L23/load.sh 2026-03-04 2026-03-05")
    ok(cur == exp, "заказы и выручка по статусам совпадают с эталоном", "суммы испорчены: откатитесь к снимку после загрузки 3 марта")
