-- Урок 22: тот же отчёт по курируемой зоне — Parquet с партициями по дню.
SELECT city, count() AS purchases, sum(amount) AS revenue
FROM s3('http://minio:9000/lake/curated/events/*/*.parquet', 'dwhadmin', 'dwh-admin-123', 'Parquet')
WHERE event_type = 'purchase' AND event_date BETWEEN '2026-03-05' AND '2026-03-07'
GROUP BY city ORDER BY city
SETTINGS use_hive_partitioning = 1, log_comment = 'lake_curated';
