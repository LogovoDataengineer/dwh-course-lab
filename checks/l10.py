"""Урок 10: SCD2 за месяц, версии без пересечений, факт ссылается на версию на дату, email как SCD1."""
from check import ok, pg, safe


def q(sql):
    return pg(sql, db="dwh")


def check():
    days = safe(q, "SELECT count(*) FROM scd.load_log", default=None)
    ok(days is not None, "в хранилище есть схема scd урока", "поднимите стенд урока: make lesson-10")
    if days is None:
        return
    n = int(days[0][0])
    ok(n >= 30, f"загружено не меньше 30 дней (сейчас {n})", "bash lessons/L10/day.sh 30")
    cur = q("SELECT (SELECT count(*) FROM scd.dim_customer WHERE is_current), (SELECT count(*) FROM scd.crm_customers)")[0]
    ok(cur[0] == cur[1], f"у каждого покупателя CRM ровно одна текущая версия ({cur[0]})")
    gaps = q("""SELECT count(*) FROM (SELECT valid_to, lead(valid_from) OVER (PARTITION BY customer_id ORDER BY valid_from) AS next_from
                FROM scd.dim_customer) t WHERE next_from IS NOT NULL AND next_from <> valid_to""")[0][0]
    ok(gaps == "0", "версии одного покупателя идут без пропусков и пересечений: конец версии = начало следующей")
    diff = q("""SELECT count(*) FROM scd.dim_customer d JOIN scd.crm_customers s USING (customer_id)
                WHERE d.is_current AND (d.city, d.segment) IS DISTINCT FROM (s.city, s.segment)""")[0][0]
    ok(diff == "0", "текущие версии совпадают с CRM по городу и сегменту")
    wrong = q("""SELECT count(*) FROM scd.fact_orders f JOIN scd.dim_customer d USING (customer_key)
                 WHERE NOT (f.order_date >= d.valid_from AND f.order_date < d.valid_to)""")[0][0]
    ok(wrong == "0", "каждый заказ ссылается на версию, действовавшую в день заказа")
    stale = int(q("""SELECT count(*) FROM scd.dim_customer d JOIN scd.crm_customers s USING (customer_id)
                     WHERE d.email IS DISTINCT FROM s.email""")[0][0])
    ok(stale == 0, f"email во всех версиях — как сейчас в CRM (устаревших: {stale})",
       "шаг 7: UPDATE в practice/L10/scd1_email.sql по всем версиям, затем bash lessons/L10/day.sh 1")
    extra = int(q("""SELECT count(*) FROM (SELECT customer_id, valid_from, lead(hashdiff) OVER (PARTITION BY customer_id ORDER BY valid_from) AS next_hash, hashdiff
                     FROM scd.dim_customer) t WHERE next_hash = hashdiff""")[0][0])
    ok(extra == 0, f"нет лишних версий, у которых изменился только email ({extra})", "email не должен входить в hashdiff")
