"""Урок 14: практикум — модель «Полки» в схеме polka базы dwh: измерения, факт продаж, воронка, витрина городов."""
from check import ok, pg, safe


def q(sql):
    return pg(sql, db="dwh")


def cols(table):
    return [r[0] for r in q(f"""SELECT column_name FROM information_schema.columns WHERE table_schema = 'polka'
                                AND table_name = '{table}' ORDER BY ordinal_position""")]


FACT = ["date_key", "customer_key", "product_key", "order_id", "status", "quantity", "amount"]
PIPE = ["order_id", "customer_key", "created_at", "paid_at", "delivered_at", "cancelled_at", "hours_to_pay"]
MART = ["city", "revenue_at_order", "revenue_now"]


def check():
    dims = safe(q, "SELECT count(*) FROM polka.dim_customer", default=None)
    ok(dims is not None, "модель собрана: в схеме polka есть измерения", "шаг 2: bash lessons/L14/build.sh")
    if dims is None:
        return
    bad = q("""SELECT (SELECT count(*) FROM (SELECT customer_id FROM polka.dim_customer WHERE customer_id IS NOT NULL
                       GROUP BY customer_id HAVING count(*) FILTER (WHERE is_current) <> 1) x),
                      (SELECT count(*) FROM polka.dim_customer a JOIN polka.dim_customer b ON a.customer_id = b.customer_id
                       AND a.customer_key < b.customer_key AND a.valid_from < b.valid_to AND b.valid_from < a.valid_to)""")[0]
    ok(bad == ["0", "0"], "в dim_customer у каждого покупателя одна текущая версия и версии не пересекаются")

    fc = cols("fact_sales")
    ok(fc == FACT, f"факт polka.fact_sales со столбцами {', '.join(FACT)}" + (f" (сейчас: {', '.join(fc)})" if fc and fc != FACT else ""),
       "шаг 3: допишите practice/L14/40_fact_sales.sql и запустите bash lessons/L14/build.sh")
    if fc == FACT:
        r = q("""SELECT (SELECT count(*) FROM polka_stg.order_items), (SELECT sum(quantity * price) FROM polka_stg.order_items),
                        (SELECT count(*) FROM polka.fact_sales), (SELECT sum(amount) FROM polka.fact_sales)""")[0]
        ok(r[0] == r[2] and r[1] == r[3], f"факт сходится с источником: строк {r[2]} из {r[0]}, сумма {r[3]} из {r[1]} ₽",
           "строки заказов не должны теряться: неизвестный товар или покупатель — ключ 0, соединения LEFT JOIN")
        unk = q("""SELECT count(*) FILTER (WHERE customer_key = 0), count(*) FILTER (WHERE product_key = 0),
                          (SELECT count(*) FROM polka_stg.order_items i WHERE NOT EXISTS
                             (SELECT 1 FROM polka_stg.products p WHERE p.product_id = i.product_id))
                   FROM polka.fact_sales""")[0]
        ok(unk[0] == "0", f"у каждой строки факта найдена версия покупателя (неизвестных: {unk[0]})",
           "шаг 4: CRM записывает регистрацию позже первого заказа — первая версия должна действовать с '1900-01-01'")
        ok(unk[1] == unk[2], f"неизвестный товар (ключ 0) — только у строк удалённых из каталога товаров ({unk[1]} из {unk[2]})")
        wrong = q("""SELECT count(*) FROM polka.fact_sales f JOIN polka_stg.orders o USING (order_id)
                     JOIN polka.dim_customer d ON d.customer_key = f.customer_key
                     WHERE f.customer_key <> 0 AND NOT (d.customer_id = o.customer_id
                           AND o.created_at >= d.valid_from AND o.created_at < d.valid_to)""")[0][0]
        ok(wrong == "0", f"ключ покупателя в факте — версия на момент заказа (ошибок: {wrong})")

    pc = cols("fact_order_pipeline")
    ok(pc == PIPE, f"воронка polka.fact_order_pipeline со столбцами {', '.join(PIPE)}" + (f" (сейчас: {', '.join(pc)})" if pc and pc != PIPE else ""),
       "шаг 5: допишите practice/L14/50_fact_order_pipeline.sql и запустите bash lessons/L14/build.sh")
    if pc == PIPE:
        diff = q("""SELECT count(*) FROM polka_stg.orders o
                    LEFT JOIN polka.fact_order_pipeline f USING (order_id)
                    LEFT JOIN (SELECT order_id, min(paid_at) AS paid_at FROM polka_stg.payments WHERE status = 'success'
                               GROUP BY order_id) p USING (order_id)
                    WHERE f.order_id IS NULL OR f.paid_at IS DISTINCT FROM p.paid_at
                       OR f.delivered_at IS DISTINCT FROM CASE WHEN o.status = 'delivered' THEN o.updated_at END
                       OR f.cancelled_at IS DISTINCT FROM CASE WHEN o.status = 'cancelled' THEN o.updated_at END
                       OR f.hours_to_pay IS DISTINCT FROM round((extract(epoch FROM p.paid_at - o.created_at) / 3600)::numeric, 1)""")[0][0]
        rows = q("SELECT count(*) FROM polka.fact_order_pipeline")[0][0]
        ok(diff == "0" and rows == q("SELECT count(*) FROM polka_stg.orders")[0][0],
           f"воронка: строка на заказ, этапы и часы до успешной оплаты совпадают с источником (расхождений: {diff})",
           "paid_at — первая УСПЕШНАЯ оплата: в payments есть попытки со status = 'failed'")

    mc = safe(cols, "city_revenue", default=[])
    ok(mc == MART, f"витрина polka.city_revenue со столбцами {', '.join(MART)}" + (f" (сейчас: {', '.join(mc)})" if mc and mc != MART else ""),
       "шаг 6: допишите practice/L14/70_city_mart.sql и запустите bash lessons/L14/build.sh")
    if mc == MART and fc == FACT:
        tot = q("""SELECT (SELECT sum(revenue_at_order) FROM polka.city_revenue), (SELECT sum(revenue_now) FROM polka.city_revenue),
                          (SELECT sum(amount) FROM polka.fact_sales WHERE status <> 'cancelled')""")[0]
        ok(tot[0] == tot[2] and tot[1] == tot[2], f"обе колонки витрины в сумме дают выручку без отмен ({tot[2]} ₽)",
           "отменённые заказы не входят; каждая продажа попадает ровно в один город в каждой колонке")
        ref = q("""SELECT count(*) FROM polka.city_revenue v FULL JOIN (
                     SELECT d.city, sum(f.amount) AS r FROM polka.fact_sales f JOIN polka.dim_customer d USING (customer_key)
                     WHERE f.status <> 'cancelled' GROUP BY d.city) a ON a.city = v.city
                   WHERE v.revenue_at_order IS DISTINCT FROM a.r""")[0][0]
        ok(ref == "0", f"выручка на момент заказа по городам совпадает с эталоном (расхождений: {ref})")
