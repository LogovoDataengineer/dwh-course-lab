-- Линк «заказ — товар»: позиции заказов.
INSERT INTO dv.link_order_product (hk_order_product, hk_order, hk_product, load_dts, record_source)
SELECT md5(concat_ws('|', s.order_id, s.product_id)), md5(s.order_id::text), md5(s.product_id::text), :'load_dts', 'site'
FROM stage_dv.site_order_items s
WHERE NOT EXISTS (SELECT 1 FROM dv.link_order_product l
                  WHERE l.hk_order_product = md5(concat_ws('|', s.order_id, s.product_id)));
