-- Урок 11: два источника «Полки» в базе сайта.
--   site_*        — сайт: покупатели, товары, заказы и позиции заказов (текущее состояние, без истории);
--   loyalty_cards — программа лояльности из старой CRM: номер клиента хранится текстом с нулями и пробелами.
-- Каждый день tick.sql меняет оба источника.
SET client_min_messages = warning;
DROP TABLE IF EXISTS site_clock, site_customers, site_products, site_orders, site_order_items, loyalty_cards;
CREATE TABLE site_clock (today date NOT NULL);
INSERT INTO site_clock VALUES ('2025-12-01');
SELECT setseed(0.1111) \g /dev/null

CREATE TABLE site_customers AS
SELECT c AS customer_id, 'Покупатель ' || c AS full_name,
       (ARRAY['Москва','Москва','Санкт-Петербург','Казань','Екатеринбург','Новосибирск'])[1 + floor(random() * 6)::int] AS city,
       'user' || c || '@mail.example' AS email
FROM generate_series(1, 30000) AS c;
ALTER TABLE site_customers ADD PRIMARY KEY (customer_id);

CREATE TABLE site_products AS
SELECT p AS product_id, 'Товар ' || p AS name,
       (ARRAY['Книги','Электроника','Дом','Одежда','Спорт'])[1 + p % 5] AS category,
       round((200 + random() * 8000)::numeric, -1) AS price
FROM generate_series(1, 400) AS p;
ALTER TABLE site_products ADD PRIMARY KEY (product_id);

CREATE TABLE site_orders (order_id integer PRIMARY KEY, customer_id integer NOT NULL, status text NOT NULL,
                          amount numeric(12, 2) NOT NULL DEFAULT 0, created_date date NOT NULL);
INSERT INTO site_orders (order_id, customer_id, status, created_date)
SELECT o, 1 + floor(random() * 30000)::int,
       CASE WHEN o > 98000 THEN 'created' WHEN o > 96500 THEN 'paid' WHEN o > 95000 THEN 'shipped'
            WHEN random() < 0.07 THEN 'cancelled' ELSE 'delivered' END,
       date '2025-12-01' - (100000 - o) / 1100
FROM generate_series(1, 100000) AS o;

CREATE TABLE site_order_items (order_id integer NOT NULL, product_id integer NOT NULL, quantity integer NOT NULL,
                               price numeric(10, 2) NOT NULL, PRIMARY KEY (order_id, product_id));
INSERT INTO site_order_items
SELECT DISTINCT ON (o.order_id, product_id) o.order_id, product_id, 1 + floor(random() * 3)::int, p.price
FROM site_orders o
CROSS JOIN LATERAL (SELECT 1 + floor(random() * 400)::int AS product_id
                    FROM generate_series(1, 1 + (o.order_id * 7) % 4)) x
JOIN site_products p USING (product_id);
UPDATE site_orders o SET amount = t.amount
FROM (SELECT order_id, sum(quantity * price) AS amount FROM site_order_items GROUP BY order_id) t
WHERE t.order_id = o.order_id;

-- Старая CRM: client_ref = номер покупателя, дополненный нулями до 7 знаков, местами с пробелами
CREATE TABLE loyalty_cards AS
SELECT CASE WHEN random() < 0.2 THEN ' ' ELSE '' END || lpad(c::text, 7, '0') || CASE WHEN random() < 0.2 THEN ' ' ELSE '' END AS client_ref,
       (ARRAY['bronze','bronze','silver','gold'])[1 + floor(random() * 4)::int] AS tier,
       floor(random() * 5000)::int AS points
FROM generate_series(1, 30000) AS c
WHERE random() < 0.6;
ALTER TABLE loyalty_cards ADD PRIMARY KEY (client_ref);
ANALYZE site_customers, site_products, site_orders, site_order_items, loyalty_cards;
