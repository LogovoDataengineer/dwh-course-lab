-- Урок 21: база интернет-магазина под нагрузкой — схема perf: 300 тысяч покупателей и 3 миллиона заказов.
-- Индекс есть только у первичных ключей: так часто и бывает, пока не начались жалобы на скорость.
SET client_min_messages = warning;
DROP SCHEMA IF EXISTS perf CASCADE;
CREATE SCHEMA perf;
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;
SELECT setseed(0.2121) \g /dev/null
CREATE TABLE perf.customers AS
SELECT c AS customer_id,
       CASE WHEN c % 3 = 0 THEN 'User' || c || '@Mail.ru' ELSE 'user' || c || '@mail.ru' END AS email,
       (ARRAY['Москва','Санкт-Петербург','Казань','Екатеринбург','Новосибирск'])[1 + c % 5] AS city,
       timestamp '2024-01-01' + (c % 700) * interval '1 day' AS registered_at
FROM generate_series(1, 300000) AS c;
ALTER TABLE perf.customers ADD PRIMARY KEY (customer_id);
CREATE TABLE perf.orders AS
SELECT o AS order_id,
       1 + floor(random() * 300000)::int AS customer_id,
       timestamp '2025-10-01' + (o / 3000000.0) * interval '180 days' AS created_at,
       CASE WHEN random() < 0.005 THEN 'processing' WHEN random() < 0.07 THEN 'cancelled' ELSE 'delivered' END AS status,
       round((300 + random() * 9000)::numeric, 2) AS amount
FROM generate_series(1, 3000000) AS o;
ALTER TABLE perf.orders ADD PRIMARY KEY (order_id);
VACUUM ANALYZE perf.customers;
VACUUM ANALYZE perf.orders;
