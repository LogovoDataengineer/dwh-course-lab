-- Урок 17: сверка текущего состояния в ClickHouse с таблицей-источником в PostgreSQL (функция postgresql()).
WITH src AS (SELECT toUInt64(order_id) AS order_id, status, toDecimal64(amount, 2) AS amount
             FROM postgresql('postgres:5432', 'shop', 'orders', 'dwh', 'dwh', 'cdc'))
SELECT (SELECT count() FROM src) AS src_orders,
       (SELECT count() FROM cdc.orders_current) AS ch_orders,
       (SELECT count() FROM cdc.orders_current WHERE order_id NOT IN (SELECT order_id FROM src)) AS deleted_but_present,
       (SELECT count() FROM src s JOIN cdc.orders_current c ON c.order_id = s.order_id
        WHERE s.status != c.status OR s.amount != c.amount) AS stale;
