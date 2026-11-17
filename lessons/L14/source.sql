-- Урок 14: источники «Полки» для практикума — схема polka в базе сайта.
-- База магазина: покупатели (текущий город), категории и товары, заказы, строки заказов, попытки оплаты.
-- CRM: история городов покупателей (city_history). Данные с настоящими шероховатостями:
--   часть товаров удалена из каталога, а строки заказов на них остались;
--   CRM записывает регистрацию с опозданием — первый заказ бывает раньше первой записи истории;
--   оплата проходит не с первой попытки: в payments есть неуспешные попытки (status = 'failed').
SET client_min_messages = warning;
DROP SCHEMA IF EXISTS polka CASCADE;
CREATE SCHEMA polka;
SELECT setseed(0.1414) \g /dev/null

CREATE TABLE polka.categories (category_id integer PRIMARY KEY, name text NOT NULL);
INSERT INTO polka.categories VALUES (1, 'Книги'), (2, 'Электроника'), (3, 'Дом'), (4, 'Спорт'), (5, 'Игрушки');
CREATE TABLE polka.products AS
SELECT p AS product_id, 'Товар ' || p AS name, 1 + p % 5 AS category_id, round((150 + random() * 6000)::numeric, -1) AS price
FROM generate_series(1, 600) AS p;
ALTER TABLE polka.products ADD PRIMARY KEY (product_id);

CREATE TABLE polka.customers AS
SELECT c AS customer_id, 'Покупатель ' || c AS full_name,
       (ARRAY['Москва','Москва','Санкт-Петербург','Казань','Екатеринбург','Новосибирск','Тула'])[1 + floor(random() * 7)::int] AS city,
       timestamp '2025-10-01' + random() * interval '170 days' AS created_at
FROM generate_series(1, 50000) AS c;
ALTER TABLE polka.customers ADD PRIMARY KEY (customer_id);

-- CRM: регистрация (с опозданием от 1 минуты до 3 часов у 3% покупателей) и переезды у 8% покупателей
CREATE TABLE polka.city_history (customer_id integer NOT NULL, city text NOT NULL, changed_at timestamp NOT NULL);
CREATE TEMP TABLE moves AS
SELECT customer_id, c.created_at, c.city AS city_now,
       (ARRAY['Москва','Санкт-Петербург','Казань','Екатеринбург','Новосибирск','Тула'])[1 + floor(random() * 6)::int] AS city_before,
       c.created_at + random() * (timestamp '2026-03-31' - c.created_at) AS moved_at,
       CASE WHEN random() < 0.03 THEN random() * interval '3 hours' ELSE interval '0' END AS crm_lag
FROM polka.customers c;
INSERT INTO polka.city_history
SELECT customer_id, CASE WHEN rn THEN city_before ELSE city_now END, created_at + crm_lag
FROM (SELECT *, random() < 0.08 AND city_before <> city_now AS rn FROM moves) m;
INSERT INTO polka.city_history
SELECT h.customer_id, m.city_now, m.moved_at
FROM polka.city_history h JOIN moves m USING (customer_id) WHERE h.city <> m.city_now;

-- заказы: январь — март 2026; первый заказ часть покупателей делает сразу после регистрации
CREATE TABLE polka.orders AS
SELECT o AS order_id, c.customer_id,
       greatest(c.created_at + interval '2 minutes', timestamp '2026-01-01' + random() * interval '89 days 23 hours') AS created_at
FROM generate_series(1, 300000) AS o
JOIN polka.customers c ON c.customer_id = 1 + (o::bigint * 7919) % 50000;
-- у 2% заказов дата — сразу после регистрации (покупатель пришёл и сразу купил)
UPDATE polka.orders o SET created_at = c.created_at + interval '2 minutes'
FROM polka.customers c WHERE c.customer_id = o.customer_id AND c.created_at >= '2026-01-01' AND random() < 0.3;
DELETE FROM polka.orders WHERE created_at >= '2026-04-01';
ALTER TABLE polka.orders ADD COLUMN status text, ADD COLUMN updated_at timestamp;
UPDATE polka.orders SET status = CASE WHEN random() < 0.08 THEN 'cancelled' WHEN created_at > '2026-03-27' THEN 'paid' ELSE 'delivered' END,
                        updated_at = created_at + (1 + random() * 4) * interval '1 day';
ALTER TABLE polka.orders ADD PRIMARY KEY (order_id);

CREATE TABLE polka.order_items AS
SELECT DISTINCT ON (o.order_id, x.product_id) o.order_id, x.product_id, 1 + floor(random() * 3)::int AS quantity, p.price
FROM polka.orders o
CROSS JOIN LATERAL (SELECT 1 + floor(random() * 600)::int AS product_id
                    FROM generate_series(1, 1 + (o.order_id * 13) % 4)) x
JOIN polka.products p ON p.product_id = x.product_id;
ALTER TABLE polka.order_items ADD PRIMARY KEY (order_id, product_id);
-- 12 товаров сняли с продажи и удалили из каталога; строки заказов на них остались
DELETE FROM polka.products WHERE product_id IN (SELECT product_id FROM polka.products ORDER BY random() LIMIT 12);

-- оплаты: успешная через несколько минут — часы после заказа; у 10% заказов перед ней неуспешная попытка
CREATE TABLE polka.payments (payment_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY, order_id integer NOT NULL,
                             paid_at timestamp NOT NULL, amount numeric(12, 2) NOT NULL, status text NOT NULL);
CREATE TEMP TABLE pay AS
SELECT o.order_id, o.created_at + (2 + random() * 600) * interval '1 minute' AS ok_at, random() < 0.10 AS had_fail,
       (SELECT sum(quantity * price) FROM polka.order_items i WHERE i.order_id = o.order_id) AS amount
FROM polka.orders o;
INSERT INTO polka.payments (order_id, paid_at, amount, status)
SELECT order_id, created_at_fail, amount, 'failed' FROM (
  SELECT p.order_id, o.created_at + (p.ok_at - o.created_at) * random() AS created_at_fail, p.amount
  FROM pay p JOIN polka.orders o USING (order_id) WHERE p.had_fail) f
UNION ALL
SELECT order_id, ok_at, amount, 'success' FROM pay;
CREATE INDEX ON polka.payments (order_id);
CREATE INDEX ON polka.city_history (customer_id, changed_at);
ANALYZE polka.categories, polka.products, polka.customers, polka.city_history, polka.orders, polka.order_items, polka.payments;
