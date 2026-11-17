"""Урок 6: модель в 3НФ с ключами, проверка без потерь и своя денормализованная витрина norm.sales_wide."""
from check import ok, pg, safe

TABLES = ["categories", "products", "customers", "orders", "order_items"]
WIDE = ["order_id", "line_no", "order_date", "customer_id", "city", "product_name", "category", "quantity", "price", "line_total"]


def check():
    have = {r[0] for r in safe(pg, "SELECT table_name FROM information_schema.tables WHERE table_schema = 'norm'", default=[])}
    ok(all(t in have for t in TABLES), "есть нормализованные таблицы norm." + ", norm.".join(TABLES), "выполните шаг 3: make psql F=lessons/L06/normalize.sql")
    if not all(t in have for t in TABLES):
        return
    cons = dict(pg("SELECT constraint_type, count(*) FROM information_schema.table_constraints WHERE table_schema = 'norm' AND constraint_type IN ('PRIMARY KEY', 'FOREIGN KEY') GROUP BY 1"))
    ok(int(cons.get("PRIMARY KEY", 0)) >= 5 and int(cons.get("FOREIGN KEY", 0)) >= 4,
       f"у таблиц есть первичные ключи ({cons.get('PRIMARY KEY', 0)}) и внешние ключи ({cons.get('FOREIGN KEY', 0)})", "пересоздайте модель: make psql F=lessons/L06/normalize.sql")
    flat, items = pg("SELECT (SELECT sum(quantity * price) FROM norm.sales_flat), (SELECT sum(quantity * price) FROM norm.order_items)")[0]
    ok(flat == items, f"выручка модели совпадает с выгрузкой ({flat})")
    has = "sales_wide" in have
    ok(has, "вы создали витрину norm.sales_wide", "шаг 6: make psql F=practice/L06/sales_wide.sql")
    if has:
        cols = [r[0] for r in pg("SELECT column_name FROM information_schema.columns WHERE table_schema = 'norm' AND table_name = 'sales_wide' ORDER BY ordinal_position")]
        missing = [c for c in WIDE if c not in cols]
        ok(not missing, "в витрине все нужные столбцы" + (f" (нет: {', '.join(missing)})" if missing else ""), "столбцы перечислены в заготовке practice/L06/sales_wide.sql")
        if not missing:
            rows, total = pg("SELECT count(*), sum(line_total) FROM norm.sales_wide")[0]
            items_rows = pg("SELECT count(*) FROM norm.order_items")[0][0]
            ok(rows == items_rows, f"строк столько же, сколько строк заказов ({rows})", "соединяйте через JOIN по ключам: размножение строк — признак лишнего соединения")
            ok(total == items, "сумма line_total равна выручке модели", "line_total = quantity * price")
            bad = pg("SELECT count(*) FROM norm.sales_wide w JOIN norm.customers c USING (customer_id) WHERE w.city IS DISTINCT FROM c.customer_city")[0][0]
            ok(bad == "0", "город в витрине — из справочника покупателей", "берите customer_city из norm.customers, а не из выгрузки")
