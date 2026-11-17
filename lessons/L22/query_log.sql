-- Урок 22: сколько прочитали оба запроса — из журнала запросов ClickHouse.
SYSTEM FLUSH LOGS;
SELECT log_comment AS zone, read_rows, formatReadableSize(read_bytes) AS read, query_duration_ms AS ms
FROM system.query_log
WHERE type = 'QueryFinish' AND log_comment IN ('lake_raw', 'lake_curated')
ORDER BY event_time DESC LIMIT 2;
