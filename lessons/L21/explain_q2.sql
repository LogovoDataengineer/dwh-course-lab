-- Урок 21: план отчёта за день — что делает PostgreSQL и сколько страниц читает.
EXPLAIN (ANALYZE, BUFFERS)
SELECT count(*), sum(amount) FROM perf.orders WHERE created_at::date = date '2025-12-15';
