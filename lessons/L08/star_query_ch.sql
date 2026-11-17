-- Урок 8: тот же вопрос к звезде в ClickHouse.
SELECT d.quarter, p.category,
       sumIf(f.amount, NOT d.is_weekend) AS weekday_revenue,
       sumIf(f.amount, d.is_weekend)     AS weekend_revenue
FROM mart.fact_sales AS f
JOIN mart.dim_date AS d    ON d.date_key = f.date_key
JOIN mart.dim_product AS p ON p.product_key = f.product_key
WHERE f.status != 'cancelled'
GROUP BY d.quarter, p.category
ORDER BY d.quarter, weekday_revenue DESC
LIMIT 7;
