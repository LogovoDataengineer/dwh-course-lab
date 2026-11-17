-- Сателлит заказа: статус, сумма, дата создания. Каждая смена статуса — новая строка.
INSERT INTO dv.sat_order (hk_order, load_dts, hashdiff, status, amount, created_date, record_source)
SELECT s.hk, :'load_dts', s.hashdiff, s.status, s.amount, s.created_date, 'site'
FROM (SELECT md5(order_id::text) AS hk, md5(concat_ws('|', status, amount, created_date)) AS hashdiff, status, amount, created_date
      FROM stage_dv.site_orders) s
LEFT JOIN (SELECT DISTINCT ON (hk_order) hk_order, hashdiff FROM dv.sat_order
           ORDER BY hk_order, load_dts DESC) last ON last.hk_order = s.hk
WHERE last.hashdiff IS DISTINCT FROM s.hashdiff;
