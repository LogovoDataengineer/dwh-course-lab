-- Урок 12: gold-покупатели по городам на каждый день — без PIT. Для каждой пары «покупатель — день»
-- два подзапроса ищут действующие версии сателлитов.
\timing on
SELECT d.snapshot_date, s.city, count(*) AS gold_customers
FROM (SELECT DISTINCT load_dts::date AS snapshot_date FROM dv.load_log) d
JOIN dv.hub_customer h ON h.load_dts < d.snapshot_date + 1
JOIN LATERAL (SELECT city FROM dv.sat_customer s
              WHERE s.hk_customer = h.hk_customer AND s.load_dts < d.snapshot_date + 1
              ORDER BY s.load_dts DESC LIMIT 1) s ON true
JOIN LATERAL (SELECT tier FROM dv.sat_customer_loyalty l
              WHERE l.hk_customer = h.hk_customer AND l.load_dts < d.snapshot_date + 1
              ORDER BY l.load_dts DESC LIMIT 1) l ON true
WHERE l.tier = 'gold'
GROUP BY 1, 2
ORDER BY 1, 2;
