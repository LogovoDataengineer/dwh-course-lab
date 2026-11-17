"""Урок 18: топик на 3 партиции, ClickHouse читает его группой clickhouse, перечитывание с дублями, ваши поминутные окна."""
from check import ch, ok, run, safe

COLS = ["window_start", "clicks", "users"]
REF = """SELECT toStartOfMinute(event_time) AS window_start, uniqExact(event_id) AS clicks, uniqExact(user_id) AS users
         FROM stream.clicks GROUP BY window_start"""


def check():
    desc = safe(run, "kafka", "/opt/kafka/bin/kafka-topics.sh", "--bootstrap-server", "localhost:9092", "--describe", "--topic", "clicks", default="")
    ok("PartitionCount: 3" in desc, "в Kafka есть топик clicks на 3 партиции", "поднимите стенд урока: make lesson-18")
    rows = safe(ch, "SELECT count(), uniqExact(event_id), uniqExact(kafka_partition) FROM stream.clicks", default=None)
    ok(rows is not None and int(rows[0][1]) > 0, f"ClickHouse читает топик: событий {rows[0][1] if rows else 0}", "шаг 2: bash lessons/L18/produce.sh 60 300")
    if rows is None or int(rows[0][1]) == 0:
        return
    total, uniq, parts = (int(x) for x in rows[0])
    ok(parts == 3, f"события пришли из всех трёх партиций ({parts})")
    grp = safe(run, "kafka", "/opt/kafka/bin/kafka-consumer-groups.sh", "--bootstrap-server", "localhost:9092", "--describe", "--group", "clickhouse", default="")
    lag = sum(int(l.split()[5]) for l in grp.splitlines() if " clicks " in f" {l} " and l.split()[5].isdigit())
    ok(grp != "" and lag == 0, f"группа clickhouse дочитала топик (lag {lag})", "если ClickHouse отключён от топика: make ch Q=\"ATTACH TABLE stream.clicks_queue\"")
    ok(total > uniq, f"топик перечитан с начала: в таблице {total - uniq} повторных событий", "шаг 5: bash lessons/L18/replay.sh")
    cols = [r[0] for r in safe(ch, "SELECT name FROM system.columns WHERE database = 'stream' AND table = 'clicks_per_minute' ORDER BY position", default=[])]
    ok(cols == COLS, f"представление stream.clicks_per_minute со столбцами {', '.join(COLS)}" + (f" (сейчас: {', '.join(cols)})" if cols and cols != COLS else ""),
       "шаг 6: допишите practice/L18/clicks_per_minute.sql и выполните make ch F=practice/L18/clicks_per_minute.sql")
    if cols != COLS:
        return
    s = ch("SELECT sum(clicks) FROM stream.clicks_per_minute")[0][0]
    ok(int(s) == uniq, f"повторы не посчитаны дважды: кликов в окнах {s}, уникальных событий {uniq}", "считайте uniqExact(event_id), а не count()")
    diff = ch(f"""SELECT (SELECT count() FROM (SELECT window_start, clicks, users FROM stream.clicks_per_minute EXCEPT {REF})) +
                         (SELECT count() FROM ({REF} EXCEPT SELECT window_start, clicks, users FROM stream.clicks_per_minute))""")[0][0]
    ok(diff == "0", f"окна построены по времени события и совпадают с эталоном (расходится окон: {diff})",
       "окно — toStartOfMinute(event_time); время прихода в Kafka (kafka_time) для окон не подходит")
