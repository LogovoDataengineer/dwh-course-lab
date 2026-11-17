-- Урок 16: продажи магазина в базе сайта (схема rel): 28 дней февраля 2026, около 60 тысяч продаж в день.
SET client_min_messages = warning;
DROP SCHEMA IF EXISTS rel CASCADE;
CREATE SCHEMA rel;
SELECT setseed(0.1616) \g /dev/null
CREATE TABLE rel.sales AS
SELECT s AS sale_id,
       timestamp '2026-02-01' + (s - 1) / 1680000.0 * interval '28 days' AS sold_at,
       (ARRAY['Москва','Москва','Санкт-Петербург','Казань','Екатеринбург','Новосибирск'])[1 + floor(random() * 6)::int] AS city,
       round((200 + random() * 6000)::numeric, -1) AS amount
FROM generate_series(1, 1680000) AS s;
ALTER TABLE rel.sales ADD PRIMARY KEY (sale_id);
CREATE INDEX ON rel.sales (sold_at);
ANALYZE rel.sales;
