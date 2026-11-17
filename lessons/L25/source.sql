-- Урок 25: заказы магазина за 1–14 марта 2026 года (схема af в базе сайта) — по 20 тысяч в день.
SET client_min_messages = warning;
DROP SCHEMA IF EXISTS af CASCADE;
CREATE SCHEMA af;
SELECT setseed(0.2525) \g /dev/null
CREATE TABLE af.orders AS
SELECT o AS order_id, timestamp '2026-03-01' + (o - 1) / 280000.0 * interval '14 days' AS created_at,
       (ARRAY['Москва','Москва','Санкт-Петербург','Казань','Екатеринбург'])[1 + floor(random() * 5)::int] AS city,
       round((300 + random() * 9000)::numeric, 2) AS amount
FROM generate_series(1, 280000) AS o;
CREATE INDEX ON af.orders (created_at);
ANALYZE af.orders;
