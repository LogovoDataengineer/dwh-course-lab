-- Урок 20: последние запросы дашборда из журнала: сколько строк прочитано и сколько это заняло.
SYSTEM FLUSH LOGS;
SELECT event_time, read_rows, formatReadableSize(read_bytes) AS read, query_duration_ms AS ms,
       formatReadableSize(memory_usage) AS memory, log_comment AS source
FROM system.query_log
WHERE type = 'QueryFinish' AND log_comment IN ('dashboard', 'dashboard_mv')
ORDER BY event_time DESC LIMIT 3;
