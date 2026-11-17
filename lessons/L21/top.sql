-- Урок 21: самые тяжёлые запросы по суммарному времени — pg_stat_statements.
SELECT calls, round(total_exec_time) AS total_ms, round(mean_exec_time::numeric, 2) AS mean_ms,
       shared_blks_hit + shared_blks_read AS blocks, left(regexp_replace(query, '\s+', ' ', 'g'), 70) AS query
FROM pg_stat_statements
WHERE query LIKE '%perf.%' AND query NOT LIKE '%pg_stat_statements%'
ORDER BY total_exec_time DESC LIMIT 5;
