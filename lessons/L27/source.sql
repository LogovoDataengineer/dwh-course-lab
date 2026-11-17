-- Урок 27: факт заказов в хранилище за 30 дней марта (схема dq базы dwh), как его загрузили ночные загрузки.
-- В выходные заказов на 30% больше. Четыре ночи прошли с инцидентами — какими, предстоит найти проверкам.
SET client_min_messages = warning;
DROP SCHEMA IF EXISTS dq CASCADE;
CREATE SCHEMA dq;
SELECT setseed(0.2727) \g /dev/null
CREATE TABLE dq.fact_orders (order_id bigint, order_date date, customer_id int, payment_method text, amount numeric(10, 2),
                             loaded_at timestamptz);
INSERT INTO dq.fact_orders
SELECT row_number() OVER () AS order_id, d::date, 1 + floor(random() * 200000)::int,
       (ARRAY['card','card','card','sbp','cash'])[1 + floor(random() * 5)::int],
       round((300 + random() * 9000)::numeric, 2), d + interval '1 day 3 hours'
FROM generate_series(date '2026-03-01', date '2026-03-30', interval '1 day') AS d,
     LATERAL generate_series(1, CASE WHEN extract(isodow FROM d) IN (6, 7) THEN 26000 ELSE 20000 END
                                + floor(random() * 1500)::int) AS n;
-- 8 марта: загрузка оборвалась на середине, и её не перезапустили — 40% заказов дня
DELETE FROM dq.fact_orders WHERE order_date = '2026-03-08' AND order_id % 10 >= 4;
-- 15 марта: в источнике сломалась запись способа оплаты — у трети заказов пусто
UPDATE dq.fact_orders SET payment_method = NULL WHERE order_date = '2026-03-15' AND order_id % 3 = 0;
-- 21 марта: пачку заказов загрузили дважды
INSERT INTO dq.fact_orders SELECT * FROM dq.fact_orders WHERE order_date = '2026-03-21' AND order_id % 20 = 0;
-- 26 марта: возвраты пришли в общую выгрузку с отрицательной суммой
UPDATE dq.fact_orders SET amount = -amount WHERE order_date = '2026-03-26' AND order_id % 50 = 0;
-- и обычный шум: единичные пустые способы оплаты в любой день — это норма, не инцидент
UPDATE dq.fact_orders SET payment_method = NULL WHERE order_id % 997 = 0 AND order_date <> '2026-03-15';
CREATE INDEX ON dq.fact_orders (order_date);
ANALYZE dq.fact_orders;
