-- Хаб покупателей: новые бизнес-ключи. Хеш-ключ — md5 от ключа, приведённого к тексту.
INSERT INTO dv.hub_customer (hk_customer, customer_id, load_dts, record_source)
SELECT md5(s.customer_id::text), s.customer_id, :'load_dts', 'site'
FROM stage_dv.site_customers s
WHERE NOT EXISTS (SELECT 1 FROM dv.hub_customer h WHERE h.hk_customer = md5(s.customer_id::text));
