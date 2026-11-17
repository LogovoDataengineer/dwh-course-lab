-- Сателлит товара: название, категория, цена.
INSERT INTO dv.sat_product (hk_product, load_dts, hashdiff, name, category, price, record_source)
SELECT s.hk, :'load_dts', s.hashdiff, s.name, s.category, s.price, 'site'
FROM (SELECT md5(product_id::text) AS hk, md5(concat_ws('|', name, category, price)) AS hashdiff, name, category, price
      FROM stage_dv.site_products) s
LEFT JOIN (SELECT DISTINCT ON (hk_product) hk_product, hashdiff FROM dv.sat_product
           ORDER BY hk_product, load_dts DESC) last ON last.hk_product = s.hk
WHERE last.hashdiff IS DISTINCT FROM s.hashdiff;
