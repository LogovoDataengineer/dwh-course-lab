-- Урок 8: вопрос бизнеса к звезде — выручка по кварталам и категориям, выходные против будней.
\timing on
SELECT d.quarter, p.category,
       sum(f.amount) FILTER (WHERE NOT d.is_weekend) AS weekday_revenue,
       sum(f.amount) FILTER (WHERE d.is_weekend)     AS weekend_revenue
FROM mart.fact_sales f
JOIN mart.dim_date d    ON d.date_key = f.date_key
JOIN mart.dim_product p ON p.product_key = f.product_key
WHERE f.status <> 'cancelled'
GROUP BY d.quarter, p.category
ORDER BY d.quarter, weekday_revenue DESC
LIMIT 7;
