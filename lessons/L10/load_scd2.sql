-- Урок 10: загрузка SCD2 за день. История ведётся по имени, городу и сегменту (hashdiff),
-- email в хеш не входит: его исправления — не новая версия покупателя (практика, шаг 7).
SELECT today AS load_date FROM scd.crm_clock \gset
CREATE TEMP TABLE snap AS
SELECT customer_id, full_name, city, segment, email,
       md5(concat_ws('|', full_name, city, segment)) AS hashdiff
FROM scd.crm_customers;

-- 1. Закрыть текущие версии изменившихся покупателей
WITH closed AS (
    UPDATE scd.dim_customer d SET valid_to = :'load_date', is_current = false
    FROM snap s
    WHERE s.customer_id = d.customer_id AND d.is_current AND d.hashdiff <> s.hashdiff
    RETURNING 1)
SELECT count(*) AS closed FROM closed \gset
-- 2 и 3. Новые версии изменившихся и первые версии новых покупателей
WITH ins AS (
    INSERT INTO scd.dim_customer (customer_id, full_name, city, segment, email, valid_from, hashdiff)
    SELECT s.customer_id, s.full_name, s.city, s.segment, s.email, :'load_date', s.hashdiff
    FROM snap s
    WHERE NOT EXISTS (SELECT 1 FROM scd.dim_customer d WHERE d.customer_id = s.customer_id AND d.is_current)
    RETURNING 1)
SELECT count(*) AS inserted FROM ins \gset

-- Факт: заказы дня со ссылкой на версию покупателя, которая действовала в день заказа
INSERT INTO scd.fact_orders
SELECT o.order_id, d.customer_key, o.order_date, o.amount
FROM scd.crm_orders o
JOIN scd.dim_customer d ON d.customer_id = o.customer_id
                       AND o.order_date >= d.valid_from AND o.order_date < d.valid_to
WHERE o.order_date = :'load_date'
ON CONFLICT (order_id) DO NOTHING;

INSERT INTO scd.load_log (load_date, closed, inserted, orders)
VALUES (:'load_date', :closed, :inserted, (SELECT count(*) FROM scd.fact_orders WHERE order_date = :'load_date'))
ON CONFLICT (load_date) DO UPDATE SET closed = EXCLUDED.closed, inserted = EXCLUDED.inserted, orders = EXCLUDED.orders, loaded_at = clock_timestamp();
