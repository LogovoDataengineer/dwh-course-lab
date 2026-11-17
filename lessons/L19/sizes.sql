-- Урок 19: размер обычной таблицы оплат и вашей колоночной (у партиционированной таблицы — сумма партиций).
SELECT 'payments (heap)' AS storage, pg_size_pretty(pg_total_relation_size('mpp.payments')) AS size
UNION ALL
SELECT 'payments_opt (ao column zstd)', pg_size_pretty(sum(pg_total_relation_size((schemaname || '.' || partitiontablename)::regclass))::bigint)
FROM pg_partitions WHERE schemaname = 'mpp' AND tablename = 'payments_opt';
