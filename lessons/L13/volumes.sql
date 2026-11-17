-- Урок 13: оценка объёмов по настоящим таблицам — сколько байт занимает строка и сколько выйдет за год.
SELECT c.relname AS table_name,
       c.reltuples::bigint AS rows,
       pg_size_pretty(pg_total_relation_size(c.oid)) AS size,
       round(pg_total_relation_size(c.oid)::numeric / c.reltuples) AS bytes_per_row,
       pg_size_pretty((pg_total_relation_size(c.oid) * 365 / 84)::bigint) AS per_year
FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname = 'taxi' AND c.relkind = 'r' AND c.reltuples > 10000
ORDER BY pg_total_relation_size(c.oid) DESC;
