-- Урок 16: дни, в которых хранилище разошлось с источником, — их и надо перегрузить (backfill).
WITH src AS (SELECT sold_at::date AS d, count(*) AS n, sum(amount) AS s FROM rel.src_sales GROUP BY 1),
     fact AS (SELECT sale_date AS d, count(*) AS n, sum(amount) AS s FROM rel.fact_sales GROUP BY 1)
SELECT d AS day, s.n AS src_sales, f.n AS dwh_sales, s.s - f.s AS amount_diff
FROM src s JOIN fact f USING (d)
WHERE (s.n, s.s) IS DISTINCT FROM (f.n, f.s)
ORDER BY d;
