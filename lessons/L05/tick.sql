-- Урок 5: проходит один час жизни магазина. Появляются новые заказы, у старых меняется статус,
-- иногда система пишет мусор: статус заглавными и с пробелами, сумму «n/a», несуществующего покупателя.
SET client_min_messages = warning;
UPDATE legacy_clock SET now_at = now_at + interval '1 hour', tick = tick + 1;
SELECT setseed(tick / 100.0) FROM legacy_clock \g /dev/null
-- оплаченные доставляем, созданные оплачиваем или отменяем
UPDATE legacy_orders o SET
    status = CASE WHEN lower(trim(status)) = 'paid' THEN 'delivered'
                  WHEN random() < 0.85 THEN 'paid' ELSE 'cancelled' END,
    updated_at = c.now_at
FROM legacy_clock c
WHERE lower(trim(o.status)) IN ('created', 'paid') AND random() < 0.6;
-- новые заказы этого часа
INSERT INTO legacy_orders
SELECT (100 + c.tick * 10 + n)::text,
       CASE WHEN n = 5 AND c.tick = 2 THEN '99' ELSE (1 + floor(random() * 12))::text END,  -- 99: такого покупателя нет
       to_char(c.now_at - (60 - n * 7) * interval '1 minute', 'YYYY-MM-DD HH24:MI:SS'),
       CASE WHEN n = 2 AND c.tick % 2 = 1 THEN ' PAID ' ELSE 'created' END,                -- кривой статус
       CASE WHEN n = 3 AND c.tick = 3 THEN 'n/a' ELSE (round((300 + random() * 9000)::numeric, -1))::text END,
       c.now_at
FROM legacy_clock c, generate_series(1, 5) AS n;
SELECT tick, now_at AS source_time,
       (SELECT count(*) FROM legacy_orders) AS orders,
       (SELECT count(*) FROM legacy_orders WHERE updated_at = now_at) AS changed_this_hour
FROM legacy_clock;
