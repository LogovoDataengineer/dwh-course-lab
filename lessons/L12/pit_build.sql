-- Урок 12: PIT покупателя на каждый загруженный день. Для каждой пары «покупатель — дата» ищем действующую
-- версию в обоих сателлитах ОДИН раз и запоминаем ссылку на неё; нет версии — ссылка на призрачную запись.
\timing on
INSERT INTO dv.pit_customer
SELECT h.hk_customer, d.snapshot_date,
       coalesce(s.hk_customer, repeat('0', 32)), coalesce(s.load_dts, '1900-01-01'),
       coalesce(l.hk_customer, repeat('0', 32)), coalesce(l.load_dts, '1900-01-01')
FROM (SELECT DISTINCT load_dts::date AS snapshot_date FROM dv.load_log) d
JOIN dv.hub_customer h ON h.load_dts < d.snapshot_date + 1
LEFT JOIN LATERAL (SELECT hk_customer, load_dts FROM dv.sat_customer s
                   WHERE s.hk_customer = h.hk_customer AND s.load_dts < d.snapshot_date + 1
                   ORDER BY s.load_dts DESC LIMIT 1) s ON true
LEFT JOIN LATERAL (SELECT hk_customer, load_dts FROM dv.sat_customer_loyalty l
                   WHERE l.hk_customer = h.hk_customer AND l.load_dts < d.snapshot_date + 1
                   ORDER BY l.load_dts DESC LIMIT 1) l ON true
ON CONFLICT DO NOTHING;
ANALYZE dv.pit_customer;
