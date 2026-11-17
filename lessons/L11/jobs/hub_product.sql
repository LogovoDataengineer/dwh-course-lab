-- Хаб товаров: новые артикулы.
INSERT INTO dv.hub_product (hk_product, product_id, load_dts, record_source)
SELECT md5(s.product_id::text), s.product_id, :'load_dts', 'site'
FROM stage_dv.site_products s
WHERE NOT EXISTS (SELECT 1 FROM dv.hub_product h WHERE h.hk_product = md5(s.product_id::text));
