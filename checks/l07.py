"""Урок 7: три выгрузки загружены конвейером, сверка сходится, новый статус отбраковывается, витрина сходится с ODS."""
from check import ok, pg, safe

GOOD = "('created', 'paid', 'delivered', 'cancelled')"


def q(sql):
    return pg(sql, db="dwh")


def check():
    log = safe(q, "SELECT batch_id, lost FROM meta.load_log ORDER BY loaded_at", default=None)
    ok(log is not None, "в базе dwh есть хранилище практикума", "поднимите стенд урока: make lesson-07")
    if log is None:
        return
    batches = {int(b) for b, _ in log}
    ok(batches >= {1, 2, 3}, f"загружены все три выгрузки (в журнале: {', '.join(map(str, sorted(batches))) or 'пусто'})",
       "bash lessons/L07/load.sh 1, затем 2 и 3")
    ok(log and log[-1][1] == "0", "последняя сверка STG и ODS: потерь нет")
    stg, ods, rej = map(int, q("SELECT (SELECT count(DISTINCT order_id) FROM stg.orders_raw), (SELECT count(*) FROM ods.orders), (SELECT count(*) FROM ods.orders_rejected)")[0])
    ok(stg == ods + rej, f"каждый заказ в одном месте: {stg} = {ods} в ODS + {rej} в отбраковке")
    orphans = int(q("SELECT count(*) FROM ods.orders_rejected WHERE reason = 'unknown customer'")[0][0])
    ok(orphans == 0, f"сирот не осталось: покупатели пришли в следующих выгрузках (сейчас {orphans})",
       "загрузите выгрузку 3: в ней приходят опоздавшие покупатели")
    bad = int(q(f"SELECT count(*) FROM ods.orders WHERE status NOT IN {GOOD}")[0][0])
    ok(bad == 0, f"в ODS только известные статусы (неизвестных: {bad})",
       "шаг 6: правило 'unknown status' в practice/L07/20_ods_orders.sql, затем снова bash lessons/L07/load.sh 3")
    unk = int(q("SELECT count(*) FROM ods.orders_rejected WHERE reason = 'unknown status'")[0][0])
    ok(unk > 0, f"заказы с новым статусом лежат в отбраковке с причиной 'unknown status' ({unk})")
    cdm, ods_rev = q("SELECT (SELECT sum(revenue) FROM cdm.daily_sales), (SELECT sum(amount) FROM ods.orders WHERE status <> 'cancelled')")[0]
    ok(cdm == ods_rev, f"витрина сходится с ODS: выручка {cdm}", "витрина считается по дням выгрузки: перезагрузите все три выгрузки по порядку")
