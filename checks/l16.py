"""Урок 16: загрузка дня под обрывами — идемпотентная и атомарная; backfill дней, изменённых в источнике задним числом."""
from check import ok, pg, safe

SCRIPT = "practice/L16/load_day.sql"
RECON = """
WITH src AS (SELECT sold_at::date AS d, count(*) AS n, sum(amount) AS s FROM rel.src_sales GROUP BY 1),
     fact AS (SELECT sale_date AS d, count(*) AS n, sum(amount) AS s, count(*) - count(DISTINCT sale_id) AS dup FROM rel.fact_sales GROUP BY 1),
     mart AS (SELECT sale_date AS d, sum(sales) AS n, sum(revenue) AS s FROM rel.daily_city GROUP BY 1)
SELECT count(f.d), count(*) FILTER (WHERE (f.n, f.s) IS DISTINCT FROM (s.n, s.s)),
       count(*) FILTER (WHERE (m.n, m.s) IS DISTINCT FROM (s.n, s.s)), coalesce(sum(f.dup), 0)
FROM src s LEFT JOIN fact f USING (d) LEFT JOIN mart m USING (d)
"""


def q(sql):
    return pg(sql, db="dwh")


def check():
    att = safe(q, f"""SELECT count(*) FILTER (WHERE script = 'lessons/L16/load_naive.sql'),
                             count(DISTINCT day) FILTER (WHERE script = '{SCRIPT}' AND outcome = 'ok'),
                             count(*) FILTER (WHERE script = '{SCRIPT}' AND outcome = 'killed')
                      FROM rel.attempts""", default=None)
    ok(att is not None, "в хранилище есть схема rel урока", "поднимите стенд урока: make lesson-16")
    if att is None:
        return
    naive, days, killed = (int(x) for x in att[0])
    ok(naive > 0, "наивная загрузка прогнана под обрывами", "шаг 2: bash lessons/L16/chaos.sh lessons/L16/load_naive.sql 2026-02-01 2026-02-28")
    ok(days >= 28, f"ваша загрузка прошла все 28 дней под обрывами (дней: {days})",
       f"шаг 4: очистите факт и запустите bash lessons/L16/chaos.sh {SCRIPT} 2026-02-01 2026-02-28")
    ok(killed >= 2, f"вашу загрузку действительно обрывали (обрывов: {killed})", "запустите chaos.sh ещё раз — обрывы случайны")
    changed = q("SELECT count(*) < 1680000 FROM rel.src_sales")[0][0] == "t"
    ok(changed, "источник изменён задним числом", "шаг 5: make psql F=lessons/L16/source_changes.sql")
    loaded, bad_fact, bad_mart, dup = q(RECON)[0]
    ok(dup == "0", f"в факте нет задвоенных продаж ({dup})", "загрузка дня должна сначала удалять день: DELETE ... WHERE sale_date = :'day'")
    ok(loaded == "28" and bad_fact == "0", f"факт совпадает с источником по всем дням (расходится дней: {bad_fact})",
       f"шаг 6: bash lessons/L16/backfill.sh {SCRIPT}")
    ok(bad_mart == "0", f"витрина совпадает с источником по всем дням (расходится дней: {bad_mart})",
       "витрина дня пересчитывается в той же транзакции, что и факт")
