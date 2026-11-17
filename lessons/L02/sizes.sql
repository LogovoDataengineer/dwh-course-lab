-- Урок 2: сколько места занимает каждая версия таблицы и каждый её столбец.
SELECT table,
       formatReadableSize(sum(data_compressed_bytes))   AS compressed,
       formatReadableSize(sum(data_uncompressed_bytes)) AS raw,
       round(sum(data_uncompressed_bytes) / sum(data_compressed_bytes), 1) AS ratio
FROM system.columns
WHERE database = 'dwh' AND table LIKE 'sales_%'
GROUP BY table
ORDER BY sum(data_compressed_bytes) DESC;
