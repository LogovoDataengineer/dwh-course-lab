-- Урок 9: события заказов «Полки» за ноябрь 2025 в базе сайта: создан → оплачен → отправлен → доставлен
-- (часть заказов отменяют до отправки) и признаки заказа: канал, промокод, подарочная упаковка.
SET client_min_messages = warning;
DROP TABLE IF EXISTS order_events, order_flags;
SELECT setseed(0.909) \g /dev/null
CREATE TABLE order_flags AS
SELECT o AS order_id,
       (ARRAY['app','app','web','web','web','marketplace'])[1 + floor(random() * 6)::int] AS channel,
       random() < 0.3 AS has_promo,
       random() < 0.08 AS gift_wrap,
       timestamp '2025-11-01' + random() * interval '30 days' AS created_at
FROM generate_series(1, 30000) AS o;
CREATE TABLE order_events (order_id integer NOT NULL, event text NOT NULL, event_time timestamp NOT NULL);
INSERT INTO order_events
SELECT order_id, 'created', created_at FROM order_flags;
INSERT INTO order_events                                   -- 90% оплачивают за 0–2 часа
SELECT order_id, 'paid', created_at + random() * interval '2 hours' FROM order_flags WHERE random() < 0.9;
INSERT INTO order_events                                   -- 8% оплаченных отменяют
SELECT e.order_id, 'cancelled', e.event_time + random() * interval '1 day'
FROM order_events e WHERE e.event = 'paid' AND random() < 0.08;
INSERT INTO order_events                                   -- остальные отправляют через 0,5–3 дня
SELECT e.order_id, 'shipped', e.event_time + (12 + random() * 60) * interval '1 hour'
FROM order_events e
WHERE e.event = 'paid' AND NOT EXISTS (SELECT 1 FROM order_events c WHERE c.order_id = e.order_id AND c.event = 'cancelled');
INSERT INTO order_events                                   -- доставка 1–6 дней, маркетплейс дольше
SELECT e.order_id, 'delivered', e.event_time + (24 + random() * 120 + CASE WHEN f.channel = 'marketplace' THEN 48 ELSE 0 END) * interval '1 hour'
FROM order_events e JOIN order_flags f USING (order_id) WHERE e.event = 'shipped';
ALTER TABLE order_flags DROP COLUMN created_at;
CREATE INDEX ON order_events (event_time);
SELECT event, count(*) FROM order_events GROUP BY event ORDER BY 2 DESC;
