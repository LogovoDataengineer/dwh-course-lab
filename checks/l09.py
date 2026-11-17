"""Урок 9: накопительный снимок загружен по дням, сходится с событиями, периодический снимок и SLA доставки по каналам."""
from check import ok, pg, safe

REFERENCE = """
SELECT p.channel, count(*), round(avg(f.hours_to_deliver), 1),
       round(100.0 * count(*) FILTER (WHERE f.hours_to_deliver <= 120) / count(*), 1)
FROM flow.fact_order_pipeline f JOIN flow.dim_order_profile p USING (profile_key)
WHERE f.delivered_at IS NOT NULL GROUP BY p.channel ORDER BY p.channel
"""


def q(sql):
    return pg(sql, db="dwh")


def check():
    days = safe(q, "SELECT count(*), coalesce(sum(events), 0) FROM flow.load_log", default=None)
    ok(days is not None, "в хранилище есть схема flow урока", "поднимите стенд урока: make lesson-09")
    if days is None:
        return
    n_days, events = map(int, days[0])
    total = int(pg("SELECT count(*) FROM order_events")[0][0])
    ok(events == total, f"все события источника загружены по дням: {events} из {total} за {n_days} дн.",
       "загрузите все дни: bash lessons/L09/day.sh 2025-11-01 2025-12-12")
    src = pg("SELECT count(*) FILTER (WHERE event = 'created'), count(*) FILTER (WHERE event = 'delivered'), count(*) FILTER (WHERE event = 'cancelled') FROM order_events")[0]
    snap = q("SELECT count(*), count(delivered_at), count(cancelled_at) FROM flow.fact_order_pipeline")[0]
    ok(src == snap, f"накопительный снимок сходится с событиями: заказов {snap[0]}, доставлено {snap[1]}, отменено {snap[2]}")
    lost = q("SELECT count(*) FROM flow.fact_order_pipeline WHERE delivered_at IS NOT NULL AND (paid_at IS NULL OR shipped_at IS NULL)")[0][0]
    ok(lost == "0", "у доставленных заказов не затёрты ранние этапы", "в MERGE даты дописываются через coalesce(f.дата, e.дата)")
    back = safe(q, "SELECT count(*) FROM flow.fact_backlog_daily", default=[["0"]])[0][0]
    ok(int(back) == 42, f"периодический снимок на каждый день с 1 ноября по 12 декабря ({back} дн.)", "шаг 5: make psql DB=dwh F=lessons/L09/backlog.sql")
    has = q("SELECT count(*) FROM information_schema.views WHERE table_schema = 'flow' AND table_name = 'delivery_sla'")[0][0] == "1"
    ok(has, "вы создали представление flow.delivery_sla", "шаг 6: make psql DB=dwh F=practice/L09/delivery_sla.sql")
    if has:
        cols = [r[0] for r in q("SELECT column_name FROM information_schema.columns WHERE table_schema = 'flow' AND table_name = 'delivery_sla' ORDER BY ordinal_position")]
        want = ["channel", "delivered", "avg_hours", "on_time_pct"]
        ok(cols == want, f"столбцы {', '.join(want)} (сейчас: {', '.join(cols)})", "переименуйте столбцы через AS")
        if cols == want:
            ok(q("SELECT * FROM flow.delivery_sla ORDER BY channel") == q(REFERENCE), "SLA по каналам совпадает с эталоном",
               "только доставленные заказы; канал — через profile_key; доля не дольше 120 часов, round(..., 1)")
