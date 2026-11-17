"""Урок 11: Data Vault за несколько дней, сателлиты только дополняются, свой сателлит лояльности из второго источника."""
from check import ok, pg, safe


def q(sql):
    return pg(sql, db="dwh")


def no_repeats(table, hk):
    """Сколько раз подряд записана та же версия: при правильной загрузке — ноль."""
    return int(q(f"""SELECT count(*) FROM (SELECT hashdiff, lag(hashdiff) OVER (PARTITION BY {hk} ORDER BY load_dts) AS prev
                     FROM dv.{table}) t WHERE hashdiff = prev""")[0][0])


def check():
    days = safe(q, "SELECT count(DISTINCT load_dts) FROM dv.load_log", default=None)
    ok(days is not None, "в хранилище есть схема dv урока", "поднимите стенд урока: make lesson-11")
    if days is None:
        return
    n = int(days[0][0])
    ok(n >= 8, f"загружено не меньше 8 дней (сейчас {n})", "шаг 3: bash lessons/L11/day.sh 7")
    hubs = q("""SELECT (SELECT count(*) FROM dv.hub_customer) = (SELECT count(*) FROM stage_dv.site_customers),
                       (SELECT count(*) FROM dv.hub_order) = (SELECT count(*) FROM stage_dv.site_orders),
                       (SELECT count(*) FROM dv.hub_product) = (SELECT count(*) FROM stage_dv.site_products)""")[0]
    ok(hubs == ["t", "t", "t"], "в хабах ровно по одной строке на каждый бизнес-ключ источника")
    links = q("""SELECT (SELECT count(*) FROM dv.link_order_customer) = (SELECT count(*) FROM stage_dv.site_orders),
                        (SELECT count(*) FROM dv.link_order_product) = (SELECT count(*) FROM stage_dv.site_order_items)""")[0]
    ok(links == ["t", "t"], "в линках по строке на каждую связь: заказ — покупатель, заказ — товар")
    stale = q("""SELECT count(*) FROM stage_dv.site_orders o
                 JOIN (SELECT DISTINCT ON (hk_order) hk_order, status FROM dv.sat_order ORDER BY hk_order, load_dts DESC) s
                   ON s.hk_order = md5(o.order_id::text)
                 WHERE s.status <> o.status""")[0][0]
    ok(stale == "0", "последние версии сателлита заказов совпадают со статусами на сайте")
    rep = sum(no_repeats(t, hk) for t, hk in (("sat_customer", "hk_customer"), ("sat_order", "hk_order"), ("sat_product", "hk_product")))
    ok(rep == 0, f"в сателлитах нет повторов одной и той же версии подряд ({rep})")

    cols = [r[0] for r in q("""SELECT column_name FROM information_schema.columns
                               WHERE table_schema = 'dv' AND table_name = 'sat_customer_loyalty' ORDER BY ordinal_position""")]
    rows = int(q("SELECT count(*) FROM dv.sat_customer_loyalty")[0][0]) if cols else 0
    ok(rows > 0, f"сателлит dv.sat_customer_loyalty загружается (строк: {rows})",
       "шаг 7: допишите INSERT в practice/L11/sat_customer_loyalty.sql и запустите bash lessons/L11/day.sh 1")
    if not rows:
        return
    orphans = int(q("""SELECT count(*) FROM dv.sat_customer_loyalty s
                       WHERE NOT EXISTS (SELECT 1 FROM dv.hub_customer h WHERE h.hk_customer = s.hk_customer)""")[0][0])
    ok(orphans == 0, f"каждая строка сателлита находит покупателя в хабе (без пары: {orphans})",
       "нормализуйте client_ref перед хешированием: убрать пробелы и нули слева, чтобы md5 совпал с md5('42')")
    src = q("SELECT DISTINCT record_source FROM dv.sat_customer_loyalty")
    ok(src == [["crm"]], "источник строк — crm", "record_source = 'crm'")
    diff = int(q("""SELECT count(*) FROM stage_dv.loyalty_cards c
                    LEFT JOIN (SELECT DISTINCT ON (hk_customer) hk_customer, tier, points FROM dv.sat_customer_loyalty
                               ORDER BY hk_customer, load_dts DESC) s ON s.hk_customer = md5(ltrim(trim(c.client_ref), '0'))
                    WHERE (s.tier, s.points) IS DISTINCT FROM (c.tier, c.points)""")[0][0])
    ok(diff == 0, f"последние версии совпадают с CRM по уровню и баллам у всех карт (расхождений: {diff})",
       "загрузите все карты; после изменения — запустите ещё один день: bash lessons/L11/day.sh 1")
    rep = no_repeats("sat_customer_loyalty", "hk_customer")
    ok(rep == 0, f"повторный запуск не плодит одинаковых версий ({rep})",
       "вставляйте строку, только если hashdiff отличается от последней версии ключа")
