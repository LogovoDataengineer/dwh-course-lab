-- Урок 22: ClickHouse читает сырые JSON прямо из посадочной зоны: выручка покупок по городам за 5–7 марта.
SELECT city, count() AS purchases, sum(toDecimal64OrZero(amount, 2)) AS revenue
FROM s3('http://minio:9000/lake/raw/events/*/*/*.json.gz', 'dwhadmin', 'dwh-admin-123', 'JSONEachRow')
WHERE event_type = 'purchase' AND event_date BETWEEN '2026-03-05' AND '2026-03-07'
GROUP BY city ORDER BY city
SETTINGS use_hive_partitioning = 1, log_comment = 'lake_raw';
