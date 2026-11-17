-- Линк «заказ — покупатель»: хеш-ключ от обоих бизнес-ключей через разделитель.
-- Хеши хабов считаются здесь же из бизнес-ключей, поэтому линк не ждёт загрузки хабов.
INSERT INTO dv.link_order_customer (hk_order_customer, hk_order, hk_customer, load_dts, record_source)
SELECT md5(concat_ws('|', s.order_id, s.customer_id)), md5(s.order_id::text), md5(s.customer_id::text), :'load_dts', 'site'
FROM stage_dv.site_orders s
WHERE NOT EXISTS (SELECT 1 FROM dv.link_order_customer l
                  WHERE l.hk_order_customer = md5(concat_ws('|', s.order_id, s.customer_id)));
