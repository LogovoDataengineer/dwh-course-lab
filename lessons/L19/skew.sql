-- Урок 19: тот же факт, распределённый по покупателю. Сколько строк на каждом сегменте и коэффициент перекоса.
SET client_min_messages = warning;
DROP TABLE IF EXISTS mpp.sales_by_customer;
CREATE TABLE mpp.sales_by_customer (LIKE mpp.fact_sales) DISTRIBUTED BY (customer_id);
INSERT INTO mpp.sales_by_customer SELECT * FROM mpp.fact_sales;
ANALYZE mpp.sales_by_customer;
SELECT 'sale_id' AS dist_key, gp_segment_id, count(*) AS rows FROM mpp.fact_sales GROUP BY 2
UNION ALL
SELECT 'customer_id', gp_segment_id, count(*) FROM mpp.sales_by_customer GROUP BY 2
ORDER BY 1 DESC, 2;
SELECT dist_key, round(max(rows) / avg(rows), 2) AS skew
FROM (SELECT 'sale_id' AS dist_key, count(*) AS rows FROM mpp.fact_sales GROUP BY gp_segment_id
      UNION ALL SELECT 'customer_id', count(*) FROM mpp.sales_by_customer GROUP BY gp_segment_id) t
GROUP BY dist_key ORDER BY 1 DESC;
