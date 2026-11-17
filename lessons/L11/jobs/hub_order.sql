-- Хаб заказов: новые номера заказов.
INSERT INTO dv.hub_order (hk_order, order_id, load_dts, record_source)
SELECT md5(s.order_id::text), s.order_id, :'load_dts', 'site'
FROM stage_dv.site_orders s
WHERE NOT EXISTS (SELECT 1 FROM dv.hub_order h WHERE h.hk_order = md5(s.order_id::text));
