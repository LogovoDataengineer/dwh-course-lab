-- Отчёт аналитика: выручка, заказы и покупатели по городам и месяцам за 2025 год.
SELECT city,
       date_trunc('month', sold_at) AS month,
       count(*)                     AS sales,
       count(DISTINCT customer_id)  AS customers,
       sum(quantity * price)        AS revenue
FROM sales_history
WHERE status <> 'cancelled'
GROUP BY city, month
ORDER BY city, month;
