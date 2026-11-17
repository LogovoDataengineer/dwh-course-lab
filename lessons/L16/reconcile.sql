-- Урок 16: сверка по дням — источник, факт и витрина. Плохой день: не совпало число продаж или сумма.
WITH src AS (SELECT sold_at::date AS d, count(*) AS n, sum(amount) AS s FROM rel.src_sales GROUP BY 1),
     fact AS (SELECT sale_date AS d, count(*) AS n, sum(amount) AS s, count(*) - count(DISTINCT sale_id) AS dup
              FROM rel.fact_sales GROUP BY 1),
     mart AS (SELECT sale_date AS d, sum(sales) AS n, sum(revenue) AS s FROM rel.daily_city GROUP BY 1)
SELECT count(*) FILTER (WHERE f.d IS NOT NULL) AS days_loaded,
       count(*) FILTER (WHERE f.d IS NOT NULL AND (f.n, f.s) IS DISTINCT FROM (s.n, s.s)) AS bad_days_fact,
       count(*) FILTER (WHERE f.d IS NOT NULL AND (m.n, m.s) IS DISTINCT FROM (f.n, f.s)) AS bad_days_mart,
       coalesce(sum(f.dup), 0) AS duplicate_rows
FROM src s LEFT JOIN fact f USING (d) LEFT JOIN mart m USING (d);
