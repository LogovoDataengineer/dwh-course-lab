-- Урок 9: загрузка событий одного дня в накопительный снимок. Запуск: bash lessons/L09/day.sh 2025-11-05
-- MERGE вставляет новые заказы и дописывает этапы существующим; coalesce не даёт затереть записанную дату пустой.
CREATE TEMP TABLE day_events AS
SELECT order_id,
       min(event_time) FILTER (WHERE event = 'created')   AS created_at,
       min(event_time) FILTER (WHERE event = 'paid')      AS paid_at,
       min(event_time) FILTER (WHERE event = 'shipped')   AS shipped_at,
       min(event_time) FILTER (WHERE event = 'delivered') AS delivered_at,
       min(event_time) FILTER (WHERE event = 'cancelled') AS cancelled_at,
       count(*) AS events
FROM flow.src_order_events
WHERE event_time >= :'day'::date AND event_time < :'day'::date + 1
GROUP BY order_id;

MERGE INTO flow.fact_order_pipeline f
USING (
    SELECT e.*, p.profile_key
    FROM day_events e
    LEFT JOIN flow.src_order_flags fl ON fl.order_id = e.order_id
    LEFT JOIN flow.dim_order_profile p ON (p.channel, p.has_promo, p.gift_wrap) = (fl.channel, fl.has_promo, fl.gift_wrap)
) e ON f.order_id = e.order_id
WHEN MATCHED THEN UPDATE SET
    paid_at      = coalesce(f.paid_at, e.paid_at),
    shipped_at   = coalesce(f.shipped_at, e.shipped_at),
    delivered_at = coalesce(f.delivered_at, e.delivered_at),
    cancelled_at = coalesce(f.cancelled_at, e.cancelled_at),
    updated_at   = clock_timestamp()
WHEN NOT MATCHED THEN INSERT (order_id, profile_key, created_at, paid_at, shipped_at, delivered_at, cancelled_at, updated_at)
    VALUES (e.order_id, e.profile_key, e.created_at, e.paid_at, e.shipped_at, e.delivered_at, e.cancelled_at, clock_timestamp());

-- ключи ролевых дат и мера «часов до доставки» — из записанных моментов
UPDATE flow.fact_order_pipeline f SET
    created_date_key   = to_char(created_at, 'YYYYMMDD')::integer,
    paid_date_key      = to_char(paid_at, 'YYYYMMDD')::integer,
    delivered_date_key = to_char(delivered_at, 'YYYYMMDD')::integer,
    hours_to_deliver   = round((extract(epoch FROM delivered_at - paid_at) / 3600)::numeric, 1)
WHERE f.order_id IN (SELECT order_id FROM day_events);

INSERT INTO flow.load_log (load_day, events, new_orders, updated_orders)
SELECT :'day'::date, coalesce(sum(events), 0), count(*) FILTER (WHERE created_at IS NOT NULL), count(*) FILTER (WHERE created_at IS NULL)
FROM day_events
ON CONFLICT (load_day) DO UPDATE SET events = EXCLUDED.events, new_orders = EXCLUDED.new_orders,
                                     updated_orders = EXCLUDED.updated_orders, loaded_at = clock_timestamp();
SELECT load_day, events, new_orders, updated_orders FROM flow.load_log WHERE load_day = :'day'::date;
