-- Сателлит линка «заказ — товар»: количество и цена позиции.
INSERT INTO dv.sat_order_product (hk_order_product, load_dts, hashdiff, quantity, price, record_source)
SELECT s.hk, :'load_dts', s.hashdiff, s.quantity, s.price, 'site'
FROM (SELECT md5(concat_ws('|', order_id, product_id)) AS hk, md5(concat_ws('|', quantity, price)) AS hashdiff, quantity, price
      FROM stage_dv.site_order_items) s
LEFT JOIN (SELECT DISTINCT ON (hk_order_product) hk_order_product, hashdiff FROM dv.sat_order_product
           ORDER BY hk_order_product, load_dts DESC) last ON last.hk_order_product = s.hk
WHERE last.hashdiff IS DISTINCT FROM s.hashdiff;
