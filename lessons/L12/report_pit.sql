-- Урок 12: тот же отчёт через PIT — только соединения по равенству.
\timing on
SELECT p.snapshot_date, s.city, count(*) AS gold_customers
FROM dv.pit_customer p
JOIN dv.sat_customer s         ON s.hk_customer = p.site_hk AND s.load_dts = p.site_ldts
JOIN dv.sat_customer_loyalty l ON l.hk_customer = p.crm_hk  AND l.load_dts = p.crm_ldts
WHERE l.tier = 'gold'
GROUP BY 1, 2
ORDER BY 1, 2;
