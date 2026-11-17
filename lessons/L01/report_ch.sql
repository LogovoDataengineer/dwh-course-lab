-- Тот же отчёт в ClickHouse: выручка, заказы и покупатели по городам и месяцам.
SELECT city,
       toStartOfMonth(sold_at)  AS month,
       count()                  AS sales,
       uniqExact(customer_id)   AS customers,
       sum(quantity * price)    AS revenue
FROM dwh.sales_history
WHERE status != 'cancelled'
GROUP BY city, month
ORDER BY city, month;
