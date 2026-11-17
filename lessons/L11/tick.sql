-- Урок 11: проходит день на сайте и в CRM. Покупатели переезжают и меняют email, меняются цены,
-- заказы проходят этапы, приходят 1500 новых заказов; в программе лояльности копятся баллы.
SET client_min_messages = warning;
UPDATE site_clock SET today = today + 1;
SELECT setseed(extract(doy FROM today) / 1000.0 + 0.5) FROM site_clock \g /dev/null
UPDATE site_customers SET city = (ARRAY['Москва','Санкт-Петербург','Казань','Екатеринбург','Новосибирск'])[1 + floor(random() * 5)::int]
WHERE random() < 0.005;
UPDATE site_customers SET email = 'u' || customer_id || '.new' || (SELECT extract(doy FROM today)::int FROM site_clock) || '@mail.example'
WHERE random() < 0.003;
UPDATE site_products SET price = round(price * (0.9 + random() * 0.25)::numeric, -1) WHERE random() < 0.03;
-- этапы заказов: часть созданных оплачивают, часть оплаченных отправляют, часть отправленных доставляют
UPDATE site_orders SET status = CASE status WHEN 'shipped' THEN 'delivered' WHEN 'paid' THEN 'shipped'
                                            ELSE CASE WHEN random() < 0.08 THEN 'cancelled' ELSE 'paid' END END
WHERE status IN ('created', 'paid', 'shipped') AND random() < 0.6;
INSERT INTO site_orders (order_id, customer_id, status, created_date)
SELECT m + n, 1 + floor(random() * 30000)::int, 'created', c.today
FROM (SELECT max(order_id) AS m FROM site_orders) x, site_clock c, generate_series(1, 1500) AS n;
INSERT INTO site_order_items
SELECT DISTINCT ON (o.order_id, product_id) o.order_id, product_id, 1 + floor(random() * 3)::int, p.price
FROM site_orders o
CROSS JOIN LATERAL (SELECT 1 + floor(random() * 400)::int AS product_id
                    FROM generate_series(1, 1 + (o.order_id * 7) % 4)) x
JOIN site_products p USING (product_id)
WHERE o.created_date = (SELECT today FROM site_clock);
UPDATE site_orders o SET amount = t.amount
FROM (SELECT i.order_id, sum(i.quantity * i.price) AS amount FROM site_order_items i
      JOIN site_orders s USING (order_id) WHERE s.created_date = (SELECT today FROM site_clock) GROUP BY i.order_id) t
WHERE t.order_id = o.order_id;
UPDATE loyalty_cards SET points = points + floor(random() * 300)::int WHERE random() < 0.04;
UPDATE loyalty_cards SET tier = CASE tier WHEN 'bronze' THEN 'silver' ELSE 'gold' END WHERE random() < 0.004;
