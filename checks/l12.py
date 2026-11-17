"""Урок 12: PIT покупателя на каждый загруженный день, ваш ежедневный снимок PIT и bridge строк заказа."""
from check import ok, pg, safe


def q(sql):
    return pg(sql, db="dwh")


REF_LATEST = """
WITH d AS (SELECT max(snapshot_date) AS day FROM dv.pit_customer),
ref AS (
  SELECT h.hk_customer,
         coalesce(s.hk_customer, repeat('0', 32)) AS site_hk, coalesce(s.load_dts, '1900-01-01') AS site_ldts,
         coalesce(l.hk_customer, repeat('0', 32)) AS crm_hk,  coalesce(l.load_dts, '1900-01-01') AS crm_ldts
  FROM d JOIN dv.hub_customer h ON h.load_dts < d.day + 1
  LEFT JOIN LATERAL (SELECT hk_customer, load_dts FROM dv.sat_customer s WHERE s.hk_customer = h.hk_customer
                     AND s.load_dts < d.day + 1 ORDER BY s.load_dts DESC LIMIT 1) s ON true
  LEFT JOIN LATERAL (SELECT hk_customer, load_dts FROM dv.sat_customer_loyalty l WHERE l.hk_customer = h.hk_customer
                     AND l.load_dts < d.day + 1 ORDER BY l.load_dts DESC LIMIT 1) l ON true)
SELECT count(*) FROM ref FULL JOIN (SELECT p.* FROM dv.pit_customer p, d WHERE p.snapshot_date = d.day) p USING (hk_customer)
WHERE (ref.site_hk, ref.site_ldts, ref.crm_hk, ref.crm_ldts) IS DISTINCT FROM (p.site_hk, p.site_ldts, p.crm_hk, p.crm_ldts)
"""


def check():
    pit = safe(q, "SELECT count(DISTINCT snapshot_date), max(snapshot_date) FROM dv.pit_customer", default=None)
    ok(pit is not None, "в хранилище есть PIT dv.pit_customer урока", "поднимите стенд урока: make lesson-12")
    if pit is None:
        return
    loaded = q("SELECT count(DISTINCT load_dts), max(load_dts)::date FROM dv.load_log")[0]
    ok(pit[0][0] != "0", f"PIT заполнена (снимков: {pit[0][0]})", "шаг 3: make psql DB=dwh F=lessons/L12/pit_build.sql")
    if pit[0][0] == "0":
        return
    ok(int(loaded[0]) >= 11, f"после сборки PIT загружен ещё хотя бы один день (последний: {loaded[1]})",
       "шаг 6: допишите practice/L12/pit_day.sql и запустите bash lessons/L12/day.sh 1")
    ok(pit[0] == loaded, f"снимок PIT есть на каждый загруженный день ({pit[0][0]} из {loaded[0]})",
       "ваш pit_day.sql должен добавлять снимок на дату :'day'; пропущенные дни дособерите: make psql DB=dwh F=lessons/L12/pit_build.sql")
    wrong = q("""SELECT count(*) FROM (SELECT p.snapshot_date, count(*) AS n,
                        (SELECT count(*) FROM dv.hub_customer h WHERE h.load_dts < p.snapshot_date + 1) AS hub
                 FROM dv.pit_customer p GROUP BY p.snapshot_date) t WHERE n <> hub""")[0][0]
    ok(wrong == "0", "в каждом снимке по строке на каждого покупателя, загруженного к этой дате",
       "покупатель попадает в снимок, если h.load_dts < :'day'::date + 1")
    dangling = q("""SELECT count(*) FROM dv.pit_customer p
                    WHERE NOT EXISTS (SELECT 1 FROM dv.sat_customer s WHERE s.hk_customer = p.site_hk AND s.load_dts = p.site_ldts)
                       OR NOT EXISTS (SELECT 1 FROM dv.sat_customer_loyalty l WHERE l.hk_customer = p.crm_hk AND l.load_dts = p.crm_ldts)""")[0][0]
    ok(dangling == "0", f"каждая ссылка PIT ведёт на существующую версию или призрачную запись (висячих: {dangling})",
       "нет версии — coalesce на repeat('0', 32) и '1900-01-01'")
    diff = q(REF_LATEST)[0][0]
    ok(diff == "0", f"последний снимок указывает на версии, действовавшие на эту дату (расхождений: {diff})",
       "берите последнюю версию с load_dts < :'day'::date + 1")
    br = q("SELECT (SELECT count(*) FROM dv.bridge_order_line), (SELECT count(*) FROM dv.link_order_product)")[0]
    ok(br[0] == br[1], f"bridge пересобран после загрузки: строк {br[0]} из {br[1]}", "bash lessons/L12/day.sh 1")
