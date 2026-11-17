-- Урок 19: данные «Полки» в Greenplum (база shop, схема mpp). 3 миллиона продаж за первый квартал 2026 года,
-- покупатели и заказы с оплатами. Покупатель 1 — партнёр-маркетплейс: на него приходится 30% всех продаж.
SET client_min_messages = warning;
DROP SCHEMA IF EXISTS mpp CASCADE;
CREATE SCHEMA mpp;
SET search_path = mpp;

CREATE TABLE dim_customer (customer_id int, segment text, city text) DISTRIBUTED BY (customer_id);
INSERT INTO dim_customer
SELECT c, (ARRAY['new','silver','gold'])[1 + c % 3],
       (ARRAY['Москва','Москва','Санкт-Петербург','Казань','Екатеринбург','Новосибирск'])[1 + c % 6]
FROM generate_series(1, 100000) c;

-- факт продаж распределён по номеру продажи — равномерно
CREATE TABLE fact_sales (sale_id bigint, customer_id int, product_id int, sale_date date, amount numeric(12, 2))
DISTRIBUTED BY (sale_id);
INSERT INTO fact_sales
SELECT g, CASE WHEN g % 10 < 3 THEN 1 ELSE (2 + (g * 7919) % 99999)::int END, (1 + (g * 31) % 5000)::int,
       date '2026-01-01' + (g % 90)::int, 100 + (g * 13) % 9000
FROM generate_series(1::bigint, 3000000) g;

-- заказы и оплаты: оплаты распределены по своему номеру, а соединяют их с заказами по order_id
CREATE TABLE orders (order_id bigint, customer_id int, created_at timestamp, status text) DISTRIBUTED BY (order_id);
INSERT INTO orders
SELECT g, (1 + (g * 7919) % 100000)::int, timestamp '2026-01-01' + (g % 90) * interval '1 day' + (g % 1440) * interval '1 minute',
       (ARRAY['delivered','delivered','delivered','paid','cancelled'])[1 + g % 5]
FROM generate_series(1::bigint, 1500000) g;
CREATE TABLE payments (payment_id bigint, order_id bigint, paid_at timestamp, method text, amount numeric(12, 2))
DISTRIBUTED BY (payment_id);
INSERT INTO payments
SELECT g, o, timestamp '2026-01-01' + (o % 90) * interval '1 day' + (o % 1380 + 5 + g % 7) * interval '1 minute',
       CASE WHEN g % 10 = 0 THEN 'bonus' ELSE 'card' END, 100 + (o * 13) % 9000
FROM (SELECT g, CASE WHEN g <= 1500000 THEN g ELSE g - 1500000 END AS o FROM generate_series(1::bigint, 1650000) g) x;
ANALYZE dim_customer; ANALYZE fact_sales; ANALYZE orders; ANALYZE payments;
