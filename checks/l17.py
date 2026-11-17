"""Урок 17: CDC из PostgreSQL через Debezium и Kafka в ClickHouse; ваше текущее состояние заказов с учётом удалений."""
import json
from check import ch, ok, pg, run, safe

COLS = ["order_id", "customer_id", "status", "amount", "updated_at"]


def check():
    st = safe(run, "connect", "curl", "-s", "localhost:8083/connectors/shop-cdc/status", default="")
    state = ""
    try:
        d = json.loads(st)
        state = d["connector"]["state"] + "/" + ",".join(t["state"] for t in d["tasks"])
    except Exception:
        pass
    ok(state == "RUNNING/RUNNING", f"коннектор shop-cdc работает ({state or 'не найден'})",
       "шаг 2: зарегистрируйте коннектор: curl -X POST -H 'Content-Type: application/json' --data @lessons/L17/connector.json localhost:8083/connectors")
    slot = safe(pg, "SELECT active FROM pg_replication_slots WHERE slot_name = 'dwh_cdc'", default=[])
    ok(slot == [["t"]], "слот репликации dwh_cdc активен", "коннектор создаёт слот сам; если Debezium остановлен — запустите его")
    ops = dict((r[0], int(r[1])) for r in safe(ch, "SELECT op, count() FROM cdc.order_events GROUP BY op", default=[]))
    ok(ops.get("r", 0) > 0, f"ClickHouse читает топик: событий снимка {ops.get('r', 0)}", "шаг 3: make ch F=lessons/L17/clickhouse.sql")
    ok(ops.get("c", 0) > 0 and ops.get("u", 0) > 0 and ops.get("d", 0) > 0,
       f"в потоке есть вставки, изменения и удаления (c {ops.get('c', 0)}, u {ops.get('u', 0)}, d {ops.get('d', 0)})",
       "шаг 4: bash lessons/L17/app.sh 30")
    cols = [r[0] for r in safe(ch, "SELECT name FROM system.columns WHERE database = 'cdc' AND table = 'orders_current' ORDER BY position", default=[])]
    ok(cols == COLS, f"представление cdc.orders_current со столбцами {', '.join(COLS)}" + (f" (сейчас: {', '.join(cols)})" if cols and cols != COLS else ""),
       "шаг 5: допишите practice/L17/orders_current.sql и выполните make ch F=practice/L17/orders_current.sql")
    if cols != COLS:
        return
    r = ch("""
        WITH src AS (SELECT toUInt64(order_id) AS order_id, status, toDecimal64(amount, 2) AS amount
                     FROM postgresql('postgres:5432', 'shop', 'orders', 'dwh', 'dwh', 'cdc'))
        SELECT (SELECT count() FROM src), (SELECT count() FROM cdc.orders_current),
               (SELECT count() FROM cdc.orders_current WHERE order_id NOT IN (SELECT order_id FROM src)),
               (SELECT count() FROM src s JOIN cdc.orders_current c ON c.order_id = s.order_id WHERE s.status != c.status OR s.amount != c.amount)""")[0]
    ok(r[2] == "0", f"удалённых в источнике заказов в текущем состоянии нет (лишних: {r[2]})",
       "если последнее событие заказа — удаление (op = 'd'), заказ из текущего состояния убирается")
    ok(r[3] == "0", f"статусы и суммы — из последнего события (устаревших: {r[3]})", "последнее — по (lsn, kafka_offset)")
    ok(r[0] == r[1], f"текущее состояние совпадает с источником: {r[1]} заказов из {r[0]}",
       "если приложение ещё работает или Debezium отстаёт, подождите несколько секунд и проверьте снова")
