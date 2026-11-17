-- Сателлит покупателя: новая строка, если hashdiff отличается от последней версии ключа (или версий нет).
INSERT INTO dv.sat_customer (hk_customer, load_dts, hashdiff, full_name, city, email, record_source)
SELECT s.hk, :'load_dts', s.hashdiff, s.full_name, s.city, s.email, 'site'
FROM (SELECT md5(customer_id::text) AS hk, md5(concat_ws('|', full_name, city, email)) AS hashdiff, full_name, city, email
      FROM stage_dv.site_customers) s
LEFT JOIN (SELECT DISTINCT ON (hk_customer) hk_customer, hashdiff FROM dv.sat_customer
           ORDER BY hk_customer, load_dts DESC) last ON last.hk_customer = s.hk
WHERE last.hashdiff IS DISTINCT FROM s.hashdiff;
